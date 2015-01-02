describe Piv::Runner do
  include Piv::Specs::CommandTestHelpers

  describe "piv [COMMAND]" do
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

            expect(prompter).to ask(a_string_matching(/start a new session\?.*\[yYnN\]/s))
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
