module Piv
  module Subcommands
    class Stories < Thor
      default_command :list

      option :format, :type => :string,
                      :default => '%default%'
      desc 'list', 'List stories'
      def list
        Application.for(self, :formatter, :projects, :shell, :stories => :predefined_formats) do
          requires_active_session!
          requires_current_project!

          format = if predefined_format?(options[:format])
                     get_format_from_metastring(options[:format])
                   else
                     options[:format]
                   end

          formatted_stories = current_project.stories.reverse.map do |story|
            parse_format_model(story, format)
          end

          more(formatted_stories.join("\n"))

          exit $?.exitstatus
        end
      end

      desc 'checkout', 'Start working on story'
      def checkout(story_id)
        Application.for(self, :projects, :formatter, :stories => :predefined_formats) do
          requires_active_session!
          requires_current_project!

          if story = current_project.stories.find_by(:id => story_id)
            story.current = true
            story.save

            say <<-MSG.strip_heredoc
              Switched to story:
                #{parse_format_model(story, get_format_from_metastring('%oneline%'))}
              MSG
            exit 0

          else
            say <<-MSG.strip_heredoc
              Unknown story:
                #{story_id}
            MSG

            exit 1
          end
        end
      end

      desc 'pull', 'Pull stories from API.'
      def pull
        Application.for(self, :projects, :iterations) do
          requires_active_session!
          requires_current_project!

          pull_iterations do |event_handler|
            event_handler.on :success do |response|
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
