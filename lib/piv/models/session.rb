module Piv
  class Session < ActiveRecord::Base
    include Concerns::Currentable

    has_many :projects

    validates_presence_of :token

    def self.start(attributes)
      self.first_or_create(attributes.slice(:token)).tap do |s|
        s.update_attributes(attributes)
        s.current = true
      end
    end


  end
end
