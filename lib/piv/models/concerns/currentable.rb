module Piv
  module Concerns
    module Currentable
      extend ActiveSupport::Concern

      included { before_save :make_only_current }

      private

      def make_only_current
        if self.current?
          self.class.where.not(:id => self.id).each do |s|
            s.update_attributes :current => false
          end
        end
      end

      module ClassMethods
        def current
          find_by(:current => true)
        end
      end

    end
  end
end
