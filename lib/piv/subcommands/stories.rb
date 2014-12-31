module Piv
  module Subcommands
    class Stories < Thor
      desc 'pull', 'Pull stories from API.'
      def pull
        Application.for(self, :projects, :stories) do
          requires_active_session!
          requires_current_project!

          pull_stories do |event_handler|
            event_handler.on :success do
              say "Updated stories.", :green
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
  end
end
