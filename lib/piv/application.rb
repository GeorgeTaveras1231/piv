module Piv
  class Application
    include Helpers::Application

    def self.for(runner, *helpers, &block)
      mods = get_helper_modules(helpers)

      self.new(runner, *helpers).tap do |application|
        application.assure_globally_installed

        application.extend(*mods)         if mods.any?
        application.instance_exec(&block) if block_given?
      end
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
      names.flat_map do |name_or_key_or_hash, nested_names|
        begin
          if name_or_key_or_hash.is_a? Hash
            get_helper_modules(name_or_key_or_hash, namespace)
          elsif nested_names
            new_namespace = namespace.const_get(name_or_key_or_hash.to_s.camelize)

            [new_namespace] + get_helper_modules([nested_names].flatten, new_namespace)
          else
            namespace.const_get(name_or_key_or_hash.to_s.camelize)
          end
        rescue NameError
          raise ArgumentError, "#{name_or_key_or_hash} is not a registered module in #{namespace}"
        end
      end
    end

  end
end
