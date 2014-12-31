module Piv
  module Helpers
    module Stories

      PERSISTED_STORY_ATTRIBUTES = %w( id name current_state estimate story_type )

      def pull_stories
        response = client.stories(:project_id => current_project.id)
        event_handler = EventHandler.new('pull stories')

        yield event_handler

        case response.status
        when 200
          stories = response.body

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

          event_handler.trigger :success, response
        else
          event_handler.trigger :failure, response
        end
      end

    end
  end
end
