
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

  describe 'whoami' do
    let(:argv) { %w( whoami ) }

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

      describe "--format" do
        let(:argv) { %W( whoami --format #{format_argument}) }

        context "%u" do
          let(:format_argument) { "i am %u" }

          it "displays the user's username" do
            allow_exit!
            expect { run_command }.to output(a_string_including("i am gtaveras")).to_stdout
          end
        end

        context "%n" do
          let(:format_argument) { "i am %n" }

          it "displays the user's name" do
            allow_exit!
            expect { run_command }.to output(a_string_including("i am George Taveras")).to_stdout
          end
        end

        context "when no format argument is given" do
          let(:argv) { %W( whoami --format ) }

          it "notifies the user that this is a required output" do
            allow_exit!
            expect { run_command }.to assert_option(:format)
          end
        end

      end
    end

    context "when there is no session in progress" do
      before do
        Piv::Session.destroy_all
      end

      it "prints a friendly message" do
        allow_exit!
        expect { run_command }.to output(/no session/).to_stderr
      end
    end
  end

  describe 'logout' do
    let(:argv) { %w( logout ) }


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

    context "when there is no session in progress" do
      before do
        Piv::Session.destroy_all
      end

      it "says there are no sessions" do
        allow_exit!
        expect { run_command }.to output(/no session/).to_stderr
      end

      it "exits with a status of 1" do
        expect { run_command }.to exit_with_code(1)
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
            let(:status) do
              400
            end

            let(:body) do
              {
                'error' => 'err msg'
              }
            end

            it "exits with a status of 1" do
              expect { run_command }.to exit_with_code(1)
            end

            it "prints the error msg" do
              allow_exit!
              expect { run_command }.to output(/err msg/).to_stderr
            end

          end
        end
      end
    end
  end
end
