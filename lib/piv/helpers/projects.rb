module Piv
  module Helpers
    module Projects

      def metachar_to_attribute_map
        {
          '%n' => :name,
          '%I' => :original_id
        }
      end

      def pull_projects
        response = client.projects(:token => current_session.token)
        event_handler = EventHandler.new('pull projects')

        yield event_handler

        case response.status
        when 200

          # TODO: attempt to update projects rather than destroy and create
          current_session.projects.destroy_all

          project_objects = response.body.map do |project|
            Project.new(:name => project['name'],
                        :original_id => project['id'])
          end

          current_session.projects << project_objects

          event_handler.trigger :success, response
        else
          event_handler.trigger :failure, response
        end
      end

      def current_projects
        current_session.projects
      end

    end
  end
end
