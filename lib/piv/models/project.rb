module Piv
  class Project < ActiveRecord::Base
    include Concerns::Currentable
    belongs_to :session
  end
end
