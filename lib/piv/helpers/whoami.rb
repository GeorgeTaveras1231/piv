module Piv
  module Helpers
    module Whoami

      def metachar_to_attribute_map
        {
          '%n' => :name,
          '%u' => :username,
          '%e' => :email,
          '%i' => :initials
        }
      end
    end
  end
end
