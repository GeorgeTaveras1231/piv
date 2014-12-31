module Piv
  module Helpers
    module Projects
      module Formatter
        def metachar_to_attribute_map
          {
            '%n' => :name,
            '%I' => :id
          }
        end
      end
    end
  end
end
