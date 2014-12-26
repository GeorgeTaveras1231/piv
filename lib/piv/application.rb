module Piv
  class Application

    HELPER_MAP = {
      :login  => Helpers::Login,
      :whoami => Helpers::Whoami,
      :logout => Helpers::Logout
    }

    def self.for(runner, *helpers, &block)
      mods = helpers.map do |helper|
        HELPER_MAP.fetch(helper.to_sym) do
          raise ArgumentError, "#{helper} is not a registered module"
        end
      end

      application = new(runner, *helpers)
      application.extend(*mods) if mods.any?

      block ||= Proc.new {}

      application.assure_globally_installed
      application.instance_exec(&block)

      application
    rescue Client::NetworkError => e
      warn application.set_color(e.message, :red)
      exit(1)
    end

    def initialize(runner, *helpers)
      @runner = runner
      @helpers = helpers
    end

    include Helpers::Application

    def method_missing(*args, &block)
      if @runner
        @runner.send(*args, &block)
      else
        super
      end
    end

  end
end
