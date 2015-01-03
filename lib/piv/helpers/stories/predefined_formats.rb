module Piv
  module Helpers
    module Stories
      module PredefinedFormats

        PREDEFINED_FORMATS = {
          :oneline =>
            "%c(yellow)%a(id)%c(cyan) %a(name)%c(clear) ( %c(red)%a(current_state ) %c(clear))",
          :pretty1 =>
            <<-FORMAT.strip_heredoc,
              %c( bold red )%cA( ' story_type ' ' - ' )
              %c(bold black on_green) %a(id) %c(magenta on_blue) %a(current_state) %c(clear)[%c(yellow bold) %a(estimate) %c(clear)] %c(cyan)%a(name)

              %iP(description 6)
          FORMAT

          :default =>
          <<-FORMAT.strip_heredoc
            %c(yellow)story #%a(id)%c(clear)
            %c(bold)title%c(clear):  %a(name)
            %c(bold)type%c(clear): %a(story_type)
            %c(bold)status%c(clear): %a(current_state)
            %c(bold)estimate%c(clear): %a(estimate)

            %iP(description 6)
          FORMAT
        }

        def format_name_from_metastring(metastring)
          /^%(?<format_key>.+)%$/ =~ metastring
          format_key && format_key.to_sym
        end

        def get_format_from_metastring(metastring, &block)
          PREDEFINED_FORMATS.fetch(format_name_from_metastring(metastring), &block)
        end
      end
    end
  end
end
