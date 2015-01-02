module Piv
  module Helpers
    module Formatter

      def parse_format(attribute_values, format_string)
        Parser.new(attribute_values).parse(format_string)
      end

      def print_formatted(attributes, format = options[:format])
        say parse_format(attributes, format)
      end

      def print_formatted_model(model, format = options[:format])
        print_formatted(model.attributes, format)
      end

      def parse_format_model(model, format = options[:format])
        parse_format(model.attributes, format)
      end

    end
  end
end
