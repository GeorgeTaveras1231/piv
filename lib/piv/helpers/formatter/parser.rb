module Piv
  module Helpers
    module Formatter
      METACHAR_FUNCTION_MAP = {
        'c' => :color,
        'a' => :attribute,
        'cA' => :center_attribute,
        'cP' => :center_paragraph,
        'iP' => :indent_paragraph
      }

      class Parser
         def initialize(attribute_map)
           @attributes = attribute_map
           @output = StringIO.new
           @thor_shell = ThorShellHelp.new(@output)
         end

        def parse(text, *function_args)
          text.gsub(metachar_regexp) do |match|
            /%(?<metachar>\w+)\((?<arguments>[^)]*)\)/ =~ match
            function = "#{METACHAR_FUNCTION_MAP[metachar]}_function"

            send(function, arguments, *function_args)
          end + color_function('clear')
        end

        def metachar_regexp
          patterns = METACHAR_FUNCTION_MAP.keys.map do |metachar|
            "%#{metachar}\\([^)]*\\)"
          end

          /#{patterns.join('|')}/
        end

        def parse_arguments(arguments)
          arguments.scan(/'[^']+'|[^\s]+/).map do |match|
            if /'(?<argument>.*)'/ =~ match
              argument
            else
              match
            end
          end
        end

        def indent_paragraph_function(arguments, attribute_values = @attributes,
          parse_arguments_with = method(:parse_arguments))

          parsed_arguments = parse_arguments_with.to_proc.call(arguments)

          attribute, indentation, padstr = parsed_arguments

          padstr ||= ' '
          indentation ||= 4

          attribute_regexp = /#{attribute_values.keys.join('|')}/

          attribute_name = attribute.scan(attribute_regexp).first

          paragraph = attribute_function(attribute_name)

          @thor_shell.indent_whole_paragraph(paragraph,
            indentation.to_i, padstr) do |line|

            attribute.gsub(attribute_regexp, line)
          end
        end

        def center_paragraph_function(arguments, attribute_values = @attributes,
          parse_arguments_with = method(:parse_arguments))

          parsed_arguments = parse_arguments_with.to_proc.call(arguments)

          attribute, padstr, total_width, line_width  = parsed_arguments

          padstr      ||= ' '
          total_width ||= @thor_shell.terminal_width
          line_width  ||= (total_width * 3 / 4)

          attribute_regexp = /#{attribute_values.keys.join('|')}/

          attribute_name = attribute.scan(attribute_regexp).first

          paragraph = attribute_function(attribute_name)

          @thor_shell.center_paragraph(paragraph, line_width.to_i, total_width.to_i, padstr) do |line|
            attribute.gsub(attribute_regexp, line)
          end

        end

        def center_attribute_function(arguments,
          attribute_values = @attributes,
          parse_arguments_with = method(:parse_arguments))

          parsed_arguments = parse_arguments_with.to_proc.call(arguments)

          attribute, padstr, width = parsed_arguments

          padstr ||= ' '
          width ||= @thor_shell.terminal_width

          attribute_regexp = /#{attribute_values.keys.join('|')}/

          attribute_name = attribute.scan(attribute_regexp).first

          attribute_value = attribute.gsub(attribute_name) do |m|
            attribute_function(m, attribute_values)
          end

          attribute_value.center(width.to_i, padstr)
        end

        def color_function(arguments, parse_arguments_with = method(:parse_arguments))
          parsed_arguments = parse_arguments_with.to_proc.call(arguments)

          @thor_shell.interpret_colors(*parsed_arguments)
        end

        def attribute_function(arguments, attribute_values = @attributes, parse_arguments_with = method(:parse_arguments))
          parsed_argument = parse_arguments_with.to_proc.call(arguments).first

          attribute_values.fetch(parsed_argument.to_sym) do
            attribute_values.fetch(parsed_argument.to_s, '').to_s
          end
        end

      end

    end
  end
end
