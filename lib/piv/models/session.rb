module Piv
  class Session < ActiveRecord::Base
    include Concerns::Currentable
    self.primary_key = :id

    has_many :projects, :dependent => :destroy

    validates_presence_of :token, :id

    def self.start(attributes)
      to_update = attributes.slice!(:token, :id)

      self.first_or_create(attributes).tap do |s|
        s.update_attributes(to_update)
        s.current = true
        s.save
      end
    end


  end
end
