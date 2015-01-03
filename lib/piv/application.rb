module Piv
  class Application
    include Helpers::Application

    def self.for(runner, *helpers, &block)
      nested_helpers = helpers.last.is_a?(Hash) ? helpers.pop : {}

      nested_mods = nested_helpers.flat_map do |namespace, helper_names|
        namespace_mod = get_helper_modules([namespace]).first

        get_helper_modules([helper_names].flatten, namespace_mod) + [namespace_mod]
      end

      mods = get_helper_modules(helpers) + nested_mods

      application = self.new(runner, *helpers)
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

    def method_missing(*args, &block)
      if @runner
        @runner.send(*args, &block)
      else
        super
      end
    end

    private

    def self.get_helper_modules(names, namespace=Helpers)
      names.map do |name|
        begin
          namespace.const_get(name.to_s.camelize)
        rescue NameError
          raise ArgumentError, "#{name} is not a registered module in #{namespace}"
        end
      end
    end

  end
end
