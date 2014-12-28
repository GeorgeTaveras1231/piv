module Piv
  class EventHandler
    def initialize(name)
      @name = name
      @registry = {}
    end

    def on(event, &callback)
      @registry[event] ||= []
      @registry[event] << callback
    end

    def off(event)
      @registry.delete(event)
    end

    def trigger(event, *args, &block)
      raise ArgumentError, "#{event} is not a registered event for #{self.inspect}" unless @registry.has_key?(event)
      @registry[event].each { |callback| callback.call(*args, &block) }
    end

    def inspect
      "<EventHandler #{@name.inspect}>"
    end
  end
end
