module Piv
  module MicroCommands
    class FailedCommandError < RuntimeError; end
    class RollbackCommand < RuntimeError; end
    class UndefinedCommand < RuntimeError; end

    class MicroCommand

      [:up, :down].each do |method|
        define_method(method) do |context={}|
          raise UndefinedCommand, "#{self.class.name.split("::").last} command has not defined ##{method}"
        end
      end

      def done?
        false
      end

      def run(direction, context={})
        direction = direction.to_sym
        directions = [:up, :down]
        unless directions.include? direction
          raise ArgumentError, '#run(direction) takes either :up or :down as argument'
        end

        opposite_direction = directions - [direction]

        self.send(direction, context)
      rescue RollbackCommand => e

        puts e.message
        puts '++ undoing changes ++'
        self.send(opposite_direction, context)
      end
    end
  end
end

Dir.glob(File.join(__dir__, 'micro_commands', '*.rb')) do |command|
  require command
end
