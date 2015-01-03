module Piv
  module MicroCommands
    class InstallGlobal < MicroCommand
      def initialize(path)
        @path = path
        @database_path = File.join(@path, '.data.sqlite3')

        @sub_commands = Mkdir.new(@path),
                        ConnectToDB.new(:adapter => :sqlite3, :database => @database_path)
      end

      def done?
        sub_commands.all?(&:done?)
      end

      def up(context={})
        sub_commands.each do |c|
          unless c.done?
            c.run(:up)
          end
        end
      rescue FailedCommandError
        raise RollbackCommand, 'rollback exception should have been caught'
      end

      def down(context={})
        if done?
          FileUtils.rm_rf @path
        end
      end

      private
        attr_reader :sub_commands
    end
  end
end
