module Piv
  module Subcommands
    class Projects < Thor
      default_command :list

      CURRENT_PROJECT_FORMAT = '* %c(green)%a(name)'
      PROJECT_FORMAT = '  %a(id): %a(name)'

      option :format, :type => :string,
                      :default => PROJECT_FORMAT,
                      :required => true

      option :cformat, :type => :string,
                       :default => CURRENT_PROJECT_FORMAT,
                       :required => true

      desc 'list', "List projects"
      def list
        Application.for(self, :formatter, :projects => [:list]) do
          requires_active_session!
          if session_projects.any?
            list_session_projects
            exit 0
          else

            pull_projects do |event_handler|
              event_handler.on :success do
                list_session_projects
                exit 0
              end

              event_handler.on :failure do |response|
                warn set_color(response.body['error'], :red)
                exit 1
              end
            end
          end
        end
      end

      desc 'pull', 'update all projects from API.'
      def pull
        Application.for(self, :projects) do
          requires_active_session!

          pull_projects do |event_handler|
            event_handler.on :success do
              say "Updated projects.", :green
              exit 0
            end

            event_handler.on :failure do |response|
              warn set_color(response.body['error'], :red)
              exit 1
            end
          end
        end
      end

      desc 'checkout (PROJECT_ID)', 'Checkout into a project'
      def checkout(project_id)
        Application.for(self) do
          requires_active_session!

          if project = Piv::Project.find_by(:id => project_id)
            project.current = true
            project.save

            say <<-MSG.strip_heredoc
            Switched to project:
              #{project.name}
            MSG

            exit 0
          else
            warn "Unknown project: #{project_id}"
            exit 1
          end
        end
      end

      option :format, :type => :string,
                      :default => CURRENT_PROJECT_FORMAT,
                      :required => true

      desc 'which', 'Print the current project'
      def which
        Application.for(self, :formatter, :projects) do
          requires_active_session!
          requires_current_project!

          print_formatted_model(current_project)

          exit 0
        end
      end

    end
  end
end
