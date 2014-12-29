module Piv
  module Helpers
    module Projects
      module Formatter
        def metachar_to_attribute_map
          {
            '%n' => :name,
            '%I' => :original_id
          }
        end
      end
    end
  end
end
