module Piv
  class Story < ActiveRecord::Base
    self.primary_key = :id
    belongs_to :project
  end
end
