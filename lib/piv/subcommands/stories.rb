module Piv
  module Subcommands
    class Stories < Thor
      default_command :list

      PRETTY_FORMAT_1 = <<-DEF
%c( bold red )%cA( ' story_type ' ' - ' )
%c(bold black on_green) %a(id) %c(magenta on_blue) %a(current_state) %c(clear)[%c(yellow bold) %a(estimate) %c(clear)] %c(cyan)%a(name)

%iP(description 6)
DEF

      PRETTY_FORMAT_ONELINE = "%c(yellow)%a(id)%c(cyan) %a(name)%c(clear) ( %c(red)%a(current_state ) %c(clear))"

      DEFAULT_FORMAT = <<-DEF
%c(yellow)story #%a(id)%c(clear)
%c(bold)title%c(clear):  %a(name)
%c(bold)type%c(clear): %a(story_type)
%c(bold)status%c(clear): %a(current_state)
%c(bold)estimate%c(clear): %a(estimate)

%iP(description 6)
DEF

      option :format, :type => :string,
                      :default => DEFAULT_FORMAT
      desc 'list', 'List stories'
      def list
        Application.for(self, :formatter, :projects, :shell) do
          requires_active_session!
          requires_current_project!

          case options[:format]
          when '%pretty1'
            options[:format] = PRETTY_FORMAT_1
          when '%oneline'
            options[:format] = PRETTY_FORMAT_ONELINE
          end

          formatted_stories = current_project.stories.reverse.map(&method(:parse_format_model))
          text = formatted_stories.join("\n")

          more(text)

          exit $?.exitstatus
        end
      end

      desc 'checkout', 'Start working on story'
      def checkout(story_id)
        Application.for(self, :projects, :formatter) do
          requires_active_session!
          requires_current_project!

          if story = current_project.stories.find_by(:id => story_id)
            story.current = true
            story.save

            say <<-MSG.strip_heredoc
              Switched to story:
                #{parse_format_model(story, PRETTY_FORMAT_ONELINE)}
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
        Application.for(self, :projects, :stories, :iterations) do
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
