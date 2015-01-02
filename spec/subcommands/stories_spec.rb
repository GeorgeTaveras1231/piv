describe Piv::Subcommands::Stories do
  include Piv::Specs::CommandTestHelpers

  describe 'stories (pull|list|checkout)' do

    describe "checkout" do
      let(:argv) do
        %W( checkout #{checkout_argument} )
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
      let(:argv) { %w( list ) }

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

      let(:argv) { %w( pull ) }

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
                { :scope => :current_backlog },
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
end
