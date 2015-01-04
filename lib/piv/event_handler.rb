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
      if @registry.has_key? event
        @registry[event].each do |callback|
          callback.call(*args, &block)
        end
      end
    end

    def inspect
      "<EventHandler #{@name.inspect}>"
    end
  end
end
