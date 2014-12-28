module Piv
  module Helpers
    module Formatter
      COLOR_METACHAR_REGEXP     = /%c\((?<color_arguments>[\w\s]*)\)/ # match %c(red on_yellow), %c(blue on_green)
      ATTRIBUTE_METACHAR_REGEXP = /%\w/                               # match %n, %i etc

      METACHAR_REGEXP = /#{COLOR_METACHAR_REGEXP}|#{ATTRIBUTE_METACHAR_REGEXP}/

      def parse_color_metachar_arguments(arg_string)
         ColorParser.parse(*arg_string.split)
      end

      def parse_format(format_string, attribute_values)
        formatted_string = format_string.gsub(METACHAR_REGEXP) do |metachar|

          if match = COLOR_METACHAR_REGEXP.match(metachar)
            parse_color_metachar_arguments(match[:color_arguments])
          elsif attribute = metachar_to_attribute_map[metachar]
            attribute_values[attribute] || attribute_values[attribute.to_s]
          else
            metachar
          end
        end

        formatted_string + parse_color_metachar_arguments("clear")
      end

      def print_formatted(attributes, format = options[:format])
        say parse_format(format, attributes)
      end

      def print_formatted_model(model, format = options[:format])
        print_formatted(model.attributes, format)
      end

    end
  end
end
