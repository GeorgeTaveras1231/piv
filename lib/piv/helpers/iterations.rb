module Piv
  module Helpers
    module Iterations

      PERSISTED_STORY_ATTRIBUTES = %w( id name current_state estimate
        story_type description )

      def save_stories_from_api_response(response_body)
          stories = response_body.flat_map do |iter|
            iter['stories']
          end

          Story.transaction do
            rel = current_project.stories
            ids = rel.pluck(:id)

            stories.each do |story|
              id = story['id'].to_s
              desired_attributes = story.slice(*PERSISTED_STORY_ATTRIBUTES)
              if ids.include? id
                rel.update(id, desired_attributes)
              else
                rel.create(desired_attributes)
              end
            end
          end
      end

      def pull_iterations(params = {})
        default_params = {
          :project_id => current_project.id,
          :scope => :current_backlog
        }

        final_params  = default_params.merge(params)
        response      = client.iterations(final_params)
        event_handler = EventHandler.new('pull iterations')

        yield event_handler

        case response.status
        when 200
          save_stories_from_api_response(response.body)

          event_handler.trigger :success, response
        else
          event_handler.trigger :failure, response
        end
      end
    end
  end
end
