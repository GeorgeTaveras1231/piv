module Piv
  module Subcommands
    class Projects < Thor
      default_command :list

      option :format, :type => :string,
                      :default => '%I: %n',
                      :required => true,
                      :desc => <<-DESC.strip_heredoc
      Format to use when printing projects
        Available meta-characters are:
          %n => name
          %I => project_id

          %c => shell colors with Thor color helpers eg: "%c(bold green on_magenta) I am colorful "

      DESC
      desc 'list', "List projects"
      def list
        Application.for(self, :formatter, :projects => [:list]) do
          requires_active_session!

          if session_projects.any?
            session_projects.each(&method(:print_formatted_model))
            exit 0
          else

            pull_projects do |event_handler|
              event_handler.on :success do
                session_projects.each(&method(:print_formatted_model))
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

          if project = Piv::Project.find_by(:original_id => project_id)
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

    end
  end
end
