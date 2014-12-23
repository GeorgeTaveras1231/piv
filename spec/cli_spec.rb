
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
      false
    end
  end
end

describe Piv::CLI do
  def allow_exit!
    @allow_exit = true
  end

  def allow_exit?
    @allow_exit
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
    silence_stream($stdout) do
      if allow_exit?
        begin
          Piv::CLI.start(argv)
        rescue SystemExit
        end
      else
        Piv::CLI.start(argv)
      end
    end
  end

  describe 'login' do
    let(:argv) { %w( login ) }
    let(:basic_auth_url) { 'https://user:password@www.pivotaltracker.com/services/v5/me' }

    describe "behavior" do

      before do
        Piv::Application.for(:login).assure_globally_installed
        stub_request(:get, basic_auth_url).to_return(
          :status => 200,
          :body => {
            :api_token => 'abc123',
            :name => 'george'}.to_json)
      end

      context 'when session is in progress and user wants to preserve session' do
        before do
          Piv::Session.create(:token => '123', :current => true)
          allow($stdin).to receive(:gets) { 'n' }
        end

        it "asks user if he wants to preserve session" do
          allow_exit!
          expect { run_command }.to output(/start a new session\?.*\[yn\].*$/i).to_stdout
        end

        it 'exits with a code of 0' do
          expect { run_command }.to exit_with_code(0)
        end
      end

      context 'when there is no session in progress' do
        before do
          Piv::Session.destroy_all
          allow($stdin).to receive(:gets).and_return('user', 'password')
        end

        it 'asks the user for credentials' do
          allow_exit!
          expect { run_command }.to output(/User: .*Password: .*/).to_stdout
          run_command
        end

        describe "<request>" do

          before do
            allow($stdin).to receive(:gets).and_return('user', 'password')
          end

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

            allow($stdin).to receive(:gets).and_return('user', 'password')
          end

          context "when response status is 200" do
            let(:status) { 200 }

            let(:body) do
              {
                'api_token' => 'abc123',
                'name' => 'George'
              }
            end

            it "exits with a code of 0" do
              expect { run_command }.to exit_with_code(0)
            end

            it "prints a welcoming message" do
              allow_exit!
              expect { run_command }.to output(/You have been authenticated./).to_stdout
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
