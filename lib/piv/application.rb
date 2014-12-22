module Piv
  class Application

    HELPER_MAP = {
      :login => Helpers::Login
    }

    def self.for(*helpers, &block)
      mods = helpers.map do |helper|
        HELPER_MAP.fetch(helper.to_sym) do
          raise ArgumentError, "#{helper} is not a registered module"
        end
      end

      application = new(*helpers)
      application.extend(*mods)

      block.call(application)
    end

    def initialize(*helpers)
      @helpers = helpers
    end

    include Helpers::Application

  end
end
