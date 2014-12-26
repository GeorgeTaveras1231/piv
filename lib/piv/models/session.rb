module Piv
  class Session < ActiveRecord::Base
    validates_presence_of :token

    def self.current
      find_by(:current => true)
    end

    def self.start(attributes)
      self.first_or_create(attributes.slice(:token)).tap do |s|
        s.update_attributes(attributes)
        s.current = true
      end
    end

    before_save :make_only_current

    private
      def make_only_current
        if self.current?
          self.class.where.not(:id => self.id).each do |s|
            s.update_attributes :current => false
          end
        end
      end

  end
end
