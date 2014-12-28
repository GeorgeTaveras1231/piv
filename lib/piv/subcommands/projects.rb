module Piv
  module Subcommands
    class Projects < Thor
      default_command :list

      option :format, :type => :string,
                      :default => '%n',
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
        Application.for(self, :projects, :formatter) do
          requires_active_session!

          if current_session.projects.any?
            current_projects.each(&method(:print_formatted_model))
            exit 0
          else

            pull_projects do |event_handler|
              event_handler.on :success do
                current_projects.each(&method(:print_formatted_model))
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

      desc 'checkout (PROJECT)', 'Checkout into a project'
      def checkout(project)
        Application.for(self) do
          requires_active_session!

        end
      end

    end
  end
end
