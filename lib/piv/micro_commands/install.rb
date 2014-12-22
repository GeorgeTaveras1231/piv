module Piv
  module MicroCommands
    class ConnectToDB < MicroCommand
      def initialize(active_record_config)
        @active_record_config = active_record_config
        ActiveRecord::Base.establish_connection(@active_record_config)
      end

      def done?
        ActiveRecord::Migrator.current_version == ActiveRecord::Migrator.last_version
      end

      def up(context={})
        silence_stream(STDOUT) do
          ActiveRecord::Migrator.migrate(
            ActiveRecord::Migrator.migrations_path)
        end
      end

      def down(context={})
        silence_stream(STDOUT) do
          ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_path, ActiveRecord::Migrator.get_all_versions.count)
        end
      end
    end

    class Mkdir < MicroCommand
      def initialize(path)
        @path = path
      end

      def done?
        Dir.exist? @path
      end

      def up(context={})
        FileUtils.mkdir_p @path
      rescue Errno::EEXIST
        raise FailedCommandError, "unable to process command because #{@path} is a file. Choose a different path for this directory or delete that file."
      end
    end

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
      rescue FailedCommand
        raise RollbackCommand, 'rollback exception should have been caught'
      end

      def down(context={})
        if done?
          FileUtils.rm_r @path
        end
      end

      private
        attr_reader :sub_commands
    end
  end
end
