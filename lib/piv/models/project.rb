module Piv
  class Project < ActiveRecord::Base
    belongs_to :session
  end
end
