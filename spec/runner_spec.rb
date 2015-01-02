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


shared_examples_for "a command that requires a current project" do
  before do
    Piv::Session.current.projects.update_all(:current => false)
  end

  it "outputs a message notifying the user that there is no current project" do
    allow_exit!
    expect { run_command }.to output(a_string_matching(/not checked out.*Run `piv projects checkout \(PROJECT_ID\)`.*/i)).to_stderr
  end

  it "exits with a status of 1" do
    expect { run_command }.to exit_with_code(1)
  end
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

    let(:current_session) do
      Piv::Session.current
    end

    let(:current_project) do
      current_session.projects.where(:current => true).first
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

    describe 'stories (pull|list|checkout)' do
      let(:argv) { %w( stories ) }

      describe "checkout" do
        let(:argv) do
          %W( stories checkout #{checkout_argument} )
        end

        let(:checkout_argument) { '890' }

        context "when story exists"
        context "when story DOESNT exists"

        before do
          Piv::Session.start(:id => '123', :token => 'abc123')
          Piv::Session.current.projects.create(:id => '345', :name => 'my proj', :current => true)
          current_project.stories.create(:id => '890', :name => 'a story')
        end

        it "sets the given  story as the current story" do
          allow_exit!
          run_command
          expect(Piv::Story.where(:current => true).pluck(:id, :name)).to contain_exactly(['890', 'a story'])
        end
      end

      describe "list" do
        it_behaves_like "a command that requires an active session"
        let(:argv) { %w( stories list ) }

        # Need to find a better way to test `more` piping
        # This is basically a unit test

        context "when there is a session in progress" do
          it_behaves_like "a command that requires a current project"

          before do
            Piv::Session.start(:token => 'abc123', :id => '123123')
          end

          context "and there is a current project" do
            before do
              current_session.projects.create(:name => 'my proj',
                :id => '123123', :current => true)
            end

            context "and there are are stories" do
              before do
                current_project.stories << stories
              end

              let(:states) do
                 %w( accepted delivered finished started rejected
                 planned unstarted unscheduled )
              end

              let(:story_types) do
                %w( feature bug chore release )
              end

              let(:stories) do
                (1..30).map do |i|
                  Piv::Story.new(:id => i.to_s,
                    :name => "story##{i}",
                    :current_state => states.sample,
                    :estimate => i % 5,
                    :story_type => story_types.sample)
                end
              end

              let(:pattern) do
                /(:?.*story#\d+.*)*/
              end

              let(:capture) do
                double(:capture, :called => nil)
              end

              let(:shell_mod_stub) do
                mod = Module.new
                mod.module_exec(capture) do |_cap|
                  define_method :more do |*args|
                    _cap.called(*args)
                  end
                end
                mod
              end

              it "outputs a list of the stories" do
                stub_const('Piv::Helpers::Shell', shell_mod_stub)
                dont_silence_stream!
                allow_exit!
                expect(capture).to receive(:called).with(a_string_matching(pattern))
                run_command
              end
            end

            context "and there are no stories"
          end
        end

      end

      describe "pull" do
        it_behaves_like "a command that requires an active session"

        let(:argv) { %w( stories pull ) }

        let(:stories_url) do
          api_url + "projects/#{project_id}/iterations"
        end

        context "when there is a session in progress" do
          it_behaves_like "a command that requires a current project"

          let(:project_id) { '123' }

          before do
            Piv::Session.start(:token => 'abc123', :id => '123123')
          end

          context "when there is a current project" do
            before do
              Piv::Session.current.projects.create(
                :name => 'my proj', :id => project_id, :current => true)

              stub_request(:get, stories_url).with(
                :query => { :scope => :current_backlog },
                :headers => {'X-Trackertoken' => 'abc123'})
                  .to_return(:body => {}.to_json)
            end

            let(:request) do
              a_request(:get, stories_url).with(
                :query =>
                  { :scope => :current_backlog},
                :headers => {'X-Trackertoken' => 'abc123'})
            end

            it "makes a request to get a list of the stories" do
              allow_exit!
              run_command
              expect(request).to have_been_made
            end

            describe "response" do
              it_behaves_like "a command that fails with an API error message"

              before do
                stub_request(:get, stories_url).with(
                  :query => { :scope => :current_backlog },
                  :headers => {'X-Trackertoken' => 'abc123'})
                  .to_return(:status => status, :body => body.to_json)
                dont_silence_stream!
              end

              context "when status is 200" do
                let(:status) { 200 }

                let(:body) do
                  [
                    {
                      :stories => [
                        {
                          :name => 'do something!',
                          :id => 123,
                          :estimate => 2,
                          :current_state => 'started',
                          :unknown_attr => 1
                        },
                        {
                          :name => 'undo nothing!',
                          :id => 345,
                          :estimate => 1,
                          :current_state => 'started',
                          :unknown_attr => 1
                        }
                      ]
                    }
                  ]
                end

                it "exits with a status of 0 "do
                  expect { run_command }.to exit_with_code(0)
                end

                context "when stories have been cached" do
                  before do
                    body.each do |iteration|
                      iteration[:stories].each do |s|
                        s[:estimate] = 0
                        current_project.stories.create(s.except(:unknown_attr))
                      end
                    end
                  end

                  it "updates the stories" do
                    allow_exit!
                    expect(current_project.stories.pluck(:estimate)).to be_all { |e| e == 0 }
                    run_command
                    expect(current_project.stories.pluck(:estimate)).to contain_exactly(2, 1)
                  end
                end

                context "when stories have not been cached" do
                  it "caches the stories" do
                    allow_exit!
                    expect(current_project.stories).to be_empty
                    run_command
                    expect(current_project.stories.pluck(:name)).to contain_exactly('do something!', 'undo nothing!')
                  end
                end
              end
            end
          end
        end
      end
    end

    describe 'projects (pull|list|checkout|which)' do
      let(:argv) { %w( projects ) }

      describe "pull" do
        it_behaves_like "a command that requires an active session"
        let(:argv) { %w( projects pull ) }

        context "when there is an active session" do
          it_behaves_like "a command that fails with an API error message"
          before do
            Piv::Session.start(:token => 'abc123', :id => '123123')
            stub_request(:get, api_url + 'projects')
              .with(:headers => {'X-Trackertoken' => 'abc123'})
              .to_return(:status => status, :body => body.to_json)
          end

          context "when response status is 200" do

            let(:status) { 200 }
            let(:body) do
              [
                {
                 "id" => 123,
                 "name" => "My Api"
                },
                {
                 "id" => 345,
                 "name" => "My UI Project"
                }
              ]
            end

            context 'when projects already exist' do
              before do
                [123, 345].each do |id|
                  current_session.projects.create(:id => id.to_s, :name =>'a proj')
                end
              end

              it "updates the projects" do
                expect(current_session.projects.pluck(:id, :name)).to contain_exactly(
                  ['123', 'a proj'], ['345', 'a proj'])
                allow_exit!
                run_command
                expect(current_session.projects.pluck(:id, :name)).to contain_exactly(
                  ['123', 'My Api'], ['345', 'My UI Project'])
              end
            end

            context 'when projects are new' do
              it "caches the projects" do
                expect(current_session.projects).to be_blank
                allow_exit!
                run_command
                expect(current_session.projects.pluck(:id, :name)).to contain_exactly(
                  ['123', 'My Api'], ['345', 'My UI Project'])
              end
            end

          end
        end
      end

      describe "checkout" do
        it_behaves_like "a command that requires an active session"
        let(:argv) { %W( projects checkout #{checkout_arguments}) }

        let(:checkout_arguments) { 'default' }

        context "when there is a session in progress" do
          before do
            current_session = Piv::Session.start(:token => 'abc123', :id => '123123')
            current_session.projects.create(:name => 'my proj', :id => 1123)
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
            Piv::Session.start(:token => 'abc123', :id => '123123')
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
          Piv::Session.start(:id => '123123',
            :token => 'abc123',
            :email => 'gtaveras@example.com',
            :name => 'George Taveras',
            :username => 'gtaveras',
            :initials => 'GT')
        end

        it "displays the username credential" do
          allow_exit!
          expect { run_command }.to output(a_string_including("gtaveras")).to_stdout
        end
      end
    end

    describe 'logout [--force]' do
      let(:argv) { %w( logout ) }

      it_behaves_like "a command that requires an active session"

      context "when there is a session in progress" do
        before do
          Piv::Session.start(:token => 'abc123', :id => '123123')

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
            Piv::Session.start(:id => '123123', :token => '123')

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
                  'id' => 123,
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
                  Piv::Session.create(:id => '123', :token => 'abc123')
                end

                it "finds that session and starts it" do
                  dont_silence_stream!
                  allow_exit!
                  run_command
                  expect(Piv::Session.where(:token => 'abc123').count).to eq 1
                end
              end

              context "and a session with the received token doesn't exist" do
                it "creates a new session with the attributes from the request" do
                  allow_exit!
                  run_command
                  session = Piv::Session.find('123')
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
