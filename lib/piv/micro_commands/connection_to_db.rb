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
  end
end
