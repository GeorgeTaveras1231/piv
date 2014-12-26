module Piv
  module Helpers
    module Whoami

      FORMAT_TO_KEY_MAP = {
        '%n' => :name,
        '%u' => :username,
        '%e' => :email,
        '%i' => :initials
      }

      PARSE_REGEXP = %r@
        (?<color_char>%c\([^)]*\))| # match %c(5), %c(1;4)
        (?<attribute_char>%\w)      # match %n, %i etc
      @x

      def parse_color_metachar(meta_char)
       /%c\((?<numbers>[\d;]+)\)/ =~ meta_char
      "\e[#{numbers}m"
      end

      def parse_format(format_string, attributes)
        formatted_string = format_string.gsub(PARSE_REGEXP) do |text|
          match_data = text.match(PARSE_REGEXP)
          if match = match_data[:color_char]
            parse_color_metachar(match)
          elsif (match = match_data[:attribute_char]) && (key = FORMAT_TO_KEY_MAP[match])
            attributes[key] || attributes[key.to_s]
          else
            text
          end
        end

        formatted_string + parse_color_metachar("%c(0)")
      end
    end
  end
end
