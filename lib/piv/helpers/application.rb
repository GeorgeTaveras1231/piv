module Piv
  class ConfigurationError < StandardError; end

  module Helpers
    module Application
      extend ActiveSupport::Concern

      module ClassMethods
        attr_accessor :global_dir, :connection
      end

      def session_in_progress?
        !!current_session
      end

      def current_session
        Session.current
      end

      def client
        @client ||= Client.new(self.class.connection) do |c|
          c.options.timeout = 4
        end
      end

      def global_installer
        @global_installer ||= MicroCommands::InstallGlobal.new(self.class.global_dir)
      end

      def assure_globally_installed
        raise ConfigurationError, "make sure connection and global directory are established" unless self.class.global_dir && self.class.connection

        global_installer.run :up unless global_installer.done?
      end

      def requires_active_session!
        unless session_in_progress?
          default_message = "There is no session in progress. Run #{set_color("`piv login`", :bold)}"
          message = block_given? ? yield(default_message) : default_message
          warn message
          exit 1
        end
      end

    end
  end
end

