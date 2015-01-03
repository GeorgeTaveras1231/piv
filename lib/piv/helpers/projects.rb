module Piv
  module Helpers
    module Projects
      PERSISTED_PROJECT_ATTRIBUTES = %w( id name )

      def pull_projects
        response = client.projects
        event_handler = EventHandler.new('pull projects')

        yield event_handler

        case response.status
        when 200
          projects = response.body

          Project.transaction do
            ids = current_session.projects.pluck(:id)
            projects.each do |project|

              id = project['id'].to_s
              desired_attributes = project.slice(*PERSISTED_PROJECT_ATTRIBUTES)

              if ids.include? id
                current_session.projects.update(id, desired_attributes)
              else
                current_session.projects.create(desired_attributes)
              end
            end

          end

          event_handler.trigger :success, response
        else
          event_handler.trigger :failure, response
        end
      end

      def session_projects
        current_session.projects
      end

      def current_project
        @current_project ||= session_projects.where(:current => true).first
      end

      def checked_out_into_project?
        !!current_project
      end

      def requires_current_project!
        default_message = "You have not checked out into a project. Run #{set_color("`piv projects checkout (PROJECT_ID)`", :bold)}"
        message = block_given? ? yield(default_message) : default_message

        assert_requirement :checked_out_into_project?, message
      end

    end
  end
end
