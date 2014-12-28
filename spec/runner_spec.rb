RSpec::Matchers.define :exit_with_code do |expected|
  supports_block_expectations
  match do |actual|
    if actual.is_a? Proc
      begin
        actual.call
      rescue SystemExit => e
        exit_code = e.status
      end
      expected == exit_code
    else
      raise ArgumentError, "actual must be a code block for this matcher"
    end
  end
end

describe Piv::Runner do

  describe "piv [COMMAND]" do

    MACROS = [:allow_exit, :dont_silence_stream]

    MACROS.each do |macro|
      instance_var = "@_#{macro}"
      define_method("#{macro}!") { instance_variable_set(instance_var, true) }
      define_method("#{macro}?") { instance_variable_get(instance_var) }
    end

    def prompter
      Thor::LineEditor
    end

    def ask(*with)
      case with.length
      when 0
        receive(:readline)
      when 1
        receive(:readline).with(*with, anything)
      else
        receive(:readline).with(*with)
      end
    end

    def assert_option(option)
      output(/No value provided for option '--#{option}'/).to_stderr
    end

    let(:global_dir) { File.join(__dir__, 'fixtures', 'piv_test') }
    let(:api_url) { "https://www.pivotaltracker.com/services/v5/" }

    let(:connection) do
      Faraday.new(api_url) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
      end
    end

    before do
      Piv::Application.global_dir = global_dir
      Piv::Application.connection = connection
    end

    after do
      if Dir.exist? global_dir
        FileUtils.rm_r global_dir
      end
    end

   let(:run_command) do
      command_proc = -> do
        if allow_exit?
          begin
            described_class.start(argv)
          rescue SystemExit
          end
        else
          described_class.start(argv)
        end
      end

      if dont_silence_stream?
        command_proc.call
      else
        silence_stream($stdout, &command_proc)
      end
    end

    before do
      Piv::Application.for(nil).assure_globally_installed
    end


    shared_examples_for "a command that requires an active session" do
      before do
        Piv::Session.destroy_all
      end

      it "exits with a status of 1" do
        expect { run_command }.to exit_with_code(1)
      end

      it "warns the user to login" do
        allow_exit!
        expect { run_command }.to output(/no session.*run `piv login`/i).to_stderr
      end
    end

    shared_examples_for "a command that fails with an API error message" do
      let(:status) { 400 }
      let(:body) do
        {
          "error" => "msg"
        }
      end

      it "prints the api errors" do
        allow_exit!
        expect { run_command }.to output(/msg/).to_stderr
      end

      it "exits with a code of 1" do
        dont_silence_stream!
        expect { run_command }.to exit_with_code(1)
      end
    end

    describe 'projects (list|checkout)' do
      let(:argv) { %w( projects ) }

      describe "pull" do
        let(:argv) { %w( projects pull ) }

        it_behaves_like "a command that requires an active session"

        context "when there is an active session" do
          before do
            Piv::Session.start(:token => 'abc123')
            stub_request(:get, api_url + 'projects')
              .with(:headers => {'X-Trackertoken' => 'abc123'})
              .to_return(:status => status, :body => body.to_json)
          end

          context "when response status is 200" do

            let(:status) { 200 }
            let(:body) do
              [
                {
                 "name" => "My Api"
                },
                {
                 "name" => "My UI Project"
                }
              ]
            end

            it "caches the projects" do
              allow_exit!
              run_command
              expect(Piv::Session.current.projects.pluck(:name)).to include("My Api", "My UI Project")
            end
          end

          context "when response status is NOT 200" do
            it_behaves_like "a command that fails with an API error message"
          end
        end
      end

      describe "checkout" do
        let(:argv) { %W( projects checkout #{checkout_arguments}) }

        let(:checkout_arguments) do
          'default'
        end

        it_behaves_like "a command that requires an active session"

        context "when there is a session in progress" do
          before do
            current_session = Piv::Session.start(:token => 'abc123')
            current_session.projects.create(:name => 'my proj', :original_id => 1123)
          end

          context "when the specified project exists" do
            let(:checkout_arguments) { '1123' }

            it "makes the chosen project the current" do
              allow_exit!
              run_command
              expect(Piv::Project.find_by(:current => true).name).to eq 'my proj'
            end

            it "exits with a status of 0" do
              expect { run_command }.to exit_with_code(0)
            end

            it "outputs some info about the projects" do
              allow_exit!
              expect { run_command }.to output(/Switched to project:.*\n.*my proj/i).to_stdout
            end
          end

          context "when the specified project does not exist" do
            let(:checkout_arguments) { '0000' }

            it "exits with a status of 1" do
              expect { run_command }.to exit_with_code(1)
            end

            it "outputs a failure message" do
              allow_exit!
              expect { run_command }.to output(/Unknown project: 0000/i).to_stderr
            end
          end

        end
      end

      describe "list" do
        it_behaves_like "a command that requires an active session"

        context "when there is a session in progress" do
          before do
            Piv::Session.start(:token => 'abc123')
          end

          let(:request) do
            a_request(:get, api_url + 'projects')
              .with(:headers => {'X-Trackertoken' => 'abc123'})
          end

          context "and that session has projects" do
            before do
              Piv::Session.current.projects << Piv::Project.new(:name => "my lonely project")
            end

            it "does not pull from api" do
              allow_exit!
              run_command
              expect(request).not_to have_been_made
            end

            it "displays the available projects" do
              allow_exit!
              expect { run_command }.to output(a_string_matching(/my lonely project/)).to_stdout
            end

            it "exits with a status of 0" do
              expect { run_command }.to exit_with_code(0)
            end
          end

          context "and that session has no projects" do
            let(:status) { 200 } # defaults
            let(:body) { {} }

            before do
              stub_request(:get, api_url + 'projects')
                .with(:headers => {'X-Trackertoken' => 'abc123'})
                .to_return(:status => status, :body => body.to_json)
            end


            it "pulls the projects from the API" do
              allow_exit!
              run_command
              expect(request).to have_been_made
            end

            context "when request status is 200" do
              let(:status) { 200 }
              let(:body) do
                [
                  {
                   "name" => "My Api",
                   "id" => "1"
                  },
                  {
                   "name" => "My UI Project",
                   "id" => "2"
                  }
                ]
              end

              it "displays the user's projects" do
                allow_exit!
                expect { run_command }.to output(a_string_matching(/1: My Api(:?\n|.)*2: My UI Project/)).to_stdout
              end

              it "exits with a code of 0" do
                expect { run_command }.to exit_with_code(0)
              end

              it "caches the projects" do
                allow_exit!
                run_command
                expect(Piv::Session.current.projects.pluck(:name)).to include("My Api", "My UI Project")
              end

              describe "--format FORMAT" do
                let(:argv) { %W( projects --format #{format_argument}) }

                context "when no format argument is given" do
                  let(:argv) { %W( projects --format ) }

                  it "notifies the user that this is a required option" do
                    allow_exit!
                    expect { run_command }.to assert_option(:format)
                  end
                end

                describe "%n" do
                  let(:format_argument) { "my project:%n" }
                  it "displays the project names" do
                    allow_exit!
                    expect { run_command }.to output(a_string_matching(/my project:My Api(:?\n|.)*my project:My UI Project/)).to_stdout
                  end
                end

                describe "%I" do
                  let(:format_argument) { "my project id:%I" }

                  it "displays the project ids" do
                    allow_exit!
                    expect { run_command }.to output(a_string_matching(/my project id:1(:?\n|.)*my project id:2/)).to_stdout
                  end
                end
              end
            end

            context "when request status is NOT 200" do
              it_behaves_like "a command that fails with an API error message"
            end

          end

        end

      end
    end

    describe 'whoami [--format FORMAT]' do
      let(:argv) { %w( whoami ) }
      it_behaves_like "a command that requires an active session"

      context "when there is a session in progress" do
        before do
          Piv::Session.start(:token => 'abc123',
            :email => 'gtaveras@example.com',
            :name => 'George Taveras',
            :username => 'gtaveras',
            :initials => 'GT')
        end

        it "displays the username credential" do
          allow_exit!
          expect { run_command }.to output(a_string_including("gtaveras")).to_stdout
        end

        describe "--format FORMAT" do
          let(:argv) { %W( whoami --format #{format_argument}) }

          describe "meta-characters" do

            describe "%u" do
              let(:format_argument) { "i am %u" }

              it "displays the user's username" do
                allow_exit!
                expect { run_command }.to output(a_string_including("i am gtaveras")).to_stdout
              end
            end

            describe "%n" do
              let(:format_argument) { "i am %n" }

              it "displays the user's name" do
                allow_exit!
                expect { run_command }.to output(a_string_including("i am George Taveras")).to_stdout
              end
            end

            describe "%e" do
              let(:format_argument) { "i am %e" }

              it "displays the user's email" do
                allow_exit!
                expect { run_command }.to output(a_string_including("i am gtaveras@example.com")).to_stdout
              end
            end

            describe "%i" do
              let(:format_argument) { "i am %i" }

              it "displays the user's initials" do
                allow_exit!
                expect { run_command }.to output(a_string_including("i am GT")).to_stdout
              end
            end

            describe "%c()" do
              let(:format_argument) { "i am %c(red on_yellow)%i" }

              it "modifies the color of the text" do
                allow_exit!
                expect { run_command }.to output(a_string_including("i am \e[31m\e[43mGT")).to_stdout
              end
            end
          end

          context "when no format argument is given" do
            let(:argv) { %W( whoami --format ) }

            it "notifies the user that this is a required option" do
              allow_exit!
              expect { run_command }.to assert_option(:format)
            end
          end
        end
      end
    end

    describe 'logout [--force]' do
      let(:argv) { %w( logout ) }

      it_behaves_like "a command that requires an active session"

      context "when there is a session in progress" do
        before do
          Piv::Session.start(:token => 'abc123')

          allow(prompter).to ask(a_string_matching(/are you sure.*\?/i)).and_return('y')
        end

        it "asks the user if to confirm" do
          allow_exit!
          expect(prompter).to ask(a_string_matching(/are you sure.*\?/i))
          run_command
        end

        it "exits with a code of 0" do
          expect { run_command }.to exit_with_code(0)
        end

        it "deletes the current session" do
          allow_exit!
          run_command
          expect(Piv::Session.current).to be_nil
        end

        describe "--force" do
          let(:argv) { %w( logout --force ) }

          it "does not ask for confirmation" do
            allow_exit!
            expect(prompter).not_to ask(a_string_matching(/are you sure.*\?/i))
            run_command
          end
        end
      end
    end

    describe 'login' do
      let(:argv) { %w( login ) }
      let(:basic_auth_url) { 'https://user:password@www.pivotaltracker.com/services/v5/me' }

      describe "behavior" do

        before do
          stub_request(:get, basic_auth_url).to_return(
            :status => 200,
            :body => {
              :api_token => 'abc123',
              :name => 'george'}.to_json)
        end

        context 'when session is in progress' do
          before do
            Piv::Session.start(:token => '123')

            allow(prompter).to ask.and_return('n')
          end

          it "asks user if he wants to preserve session" do
            allow_exit!

            expect(prompter).to ask(a_string_matching(/start a new session\?\[yYnN\]/i))
            run_command
          end

          it 'exits with a code of 0' do
            expect { run_command }.to exit_with_code(0)
          end
        end

        context 'when there is no session in progress' do
          before do
            Piv::Session.destroy_all
            allow(prompter).to ask.and_return('y')
            allow(prompter).to ask(a_string_matching(/User:.*/)).and_return('user')
            allow(prompter).to ask(a_string_matching(/Password:.*/), :echo => false).and_return('password')
          end

          it 'asks the user for credentials' do
            allow_exit!
            expect(prompter).to ask(a_string_matching(/User:.*/))
            expect(prompter).to ask(a_string_matching(/Password:.*/), :echo => false)
            run_command
          end

          describe "<request>" do

            let(:request) do
              a_request(:get, basic_auth_url)
            end

            it "makes a login request with user credentials" do
              allow_exit!
              run_command
              expect(request).to have_been_made
            end
          end

          describe "<response>" do
            before do
              stub_request(:get, basic_auth_url).to_return(
                :status => status,
                :body => body.to_json)
            end

            context "when response status is 200" do
              let(:status) { 200 }

              let(:body) do
                {
                  'api_token' => 'abc123',
                  'name' => 'George',
                  'email' => 'gtaveras@example.com',
                  'initials' => 'GT',
                  'username' => 'gtaveras'
                }
              end

              it "exits with a code of 0" do
                expect { run_command }.to exit_with_code(0)
              end

              it "prints a welcoming message" do
                allow_exit!
                expect { run_command }.to output(/You have been authenticated./).to_stdout
              end

              context "and a session with the received token already exists" do
                before do
                  Piv::Session.create(:token => 'abc123')
                end

                it "finds that session and starts it" do
                  allow_exit!
                  run_command
                  expect(Piv::Session.where(:token => 'abc123').count).to eq 1
                end
              end

              context "and a session with the received token doesn't exist" do
                it "creates a new session with the attributes from the request" do
                  allow_exit!
                  run_command
                  session = Piv::Session.find_by_token('abc123')
                  expect(session.name).to eq('George')
                  expect(session.email).to eq('gtaveras@example.com')
                  expect(session.initials).to eq('GT')
                  expect(session.username).to eq('gtaveras')
                end
              end
            end

            context "when response status is not 200" do
              it_behaves_like "a command that fails with an API error message"
            end
          end
        end
      end
    end
  end
end
