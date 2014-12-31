module Piv
  class Project < ActiveRecord::Base
    include Concerns::Currentable
    self.primary_key = :id
    belongs_to :session
    has_many :stories
  end
end
