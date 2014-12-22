require 'spec_helper'

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
  let(:global_dir) { File.join(__dir__, 'fixtures', 'piv_test') }

  let(:api_url) do
    "https://www.pivotaltracker.com/services/v5/"
  end

  before do
    Piv::Application.global_dir = global_dir
  end

  after do
    if Dir.exist? global_dir
      FileUtils.rm_r global_dir
    end
  end

  let(:run_command) do
    if defined? stub_exit
      begin
        Piv::CLI.start(argv)
      rescue SystemExit
      end
    else
      Piv::CLI.start(argv)
    end
  end

  describe 'login' do
    let(:argv) { %w( login ) }

    let(:application) do
      double(:application,
        :assure_globally_installed => nil,
        :session_in_progress? => session_in_progress?,
        :user_wants_to_preserve_session? => user_wants_to_preserve_session?,
        )
    end

    before do
      allow(Piv::Session).to receive(:first_or_create) { session }

      allow(Piv::Application).to receive(:for).with(:login).and_yield(application)
    end

    context "always" do
      let(:session_in_progress?) { true }
      let(:user_wants_to_preserve_session?) { true }
      let(:stub_exit) { true }

      it "assures piv is globally installed" do
        expect(application).to receive(:assure_globally_installed)
        run_command
      end
    end

    context 'when session is in progress and user wants to preserve session' do
      let(:session_in_progress?) { true }
      let(:user_wants_to_preserve_session?) { true }

      it 'exits with a code of 0' do
        expect { run_command }.to exit_with_code(0)
      end
    end

    context 'when there is no session in progress' do
      let(:session_in_progress?) { false }
      let(:user_wants_to_preserve_session?) { false }

      before do
        allow(application).to receive(:ask_for_credentials) { ['user', 'password'] }
        allow(application).to receive(:client) { client }

        allow(Piv::Session).to receive(:first_or_create) { session }
      end

      let(:session) { double(:session, :current= => true, :save => true) }
      let(:client) { double(:client, :login => response) }

      let(:response) { double(:response, :status => nil, :body => {}) }

      describe do
        let(:stub_exit) { true }

        it 'asks the user for credentials' do
          expect(application).to receive(:ask_for_credentials)
          run_command
        end
      end

      describe "<request>" do

        context "always" do

          let(:stub_exit) { true }

          it "makes a login request with user credentials" do
            expect(client).to receive(:login)
              .with(:user => 'user', :password => 'password')

            run_command
          end
        end

        describe "<response>" do
          context "when there is a server error" do
            before do
              allow(client).to receive(:login) { raise Piv::Client::NetworkError, 'somsom' }
            end

            it "exits with a status of 1" do
              expect { run_command }.to exit_with_code(1)
            end

            describe do
              let(:stub_exit) { true }

              it "prints the error msg" do
                expect { run_command }.to output(/somsom/).to_stderr
              end
            end
          end

          context "when response status is 200" do
            let(:response) do
              double(:response, :status => 200, :body => body)
            end

            let(:body) do
              {
                'api_token' => 'abc123',
                'name' => 'George'
              }
            end

            it "exits with a code of 0" do
              expect { run_command }.to exit_with_code(0)
            end

            describe do
              let(:stub_exit) { true }

              it "prints a welcoming message" do
                expect { run_command }.to output(/You have been authenticated./).to_stdout
              end
            end

          end

          context "when response status is not 200" do
            let(:response) do
              double(:response, :status => 400, :body => body)
            end

            let(:body) do
              {
                'error' => 'err msg'
              }
            end


            it "exits with a status of 1" do
              expect { run_command }.to exit_with_code(1)
            end

            describe do
              let(:stub_exit) { true }

              it "prints the error msg" do
                expect { run_command }.to output(/err msg/).to_stderr
              end
            end

          end
        end
      end
    end

  end
end
