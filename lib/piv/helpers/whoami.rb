module Piv
  module Helpers
    module Whoami
      FORMAT_MAP = {
        '%n' => '%{name}',
        '%u' => '%{username}'
      }

      def gsub_regexp
        /#{FORMAT_MAP.keys.join('|')}/
      end

      def parse_format(format_string, attributes)
        format_string.gsub(gsub_regexp, FORMAT_MAP) % attributes.symbolize_keys
      end
    end
  end
end
