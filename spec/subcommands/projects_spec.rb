describe Piv::Subcommands::Projects do
  include Piv::Specs::CommandTestHelpers

  describe 'projects (pull|list|checkout|which)' do

    describe "pull" do
      it_behaves_like "a command that requires an active session"
      let(:argv) { %w( pull ) }

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
      let(:argv) { %W( checkout #{checkout_arguments}) }

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

      let(:argv) { %w( list ) }

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
end
