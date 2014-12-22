module Piv
  module Helpers
    module Application
      extend ActiveSupport::Concern

      # TODO: Move to config file
      API_URL = "https://www.pivotaltracker.com/services/v5/"

      module ClassMethods
        attr_accessor :global_dir
      end

      def session_in_progress?
        !!current_session
      end

      def current_session
        Session.current
      end

      def client
        @client ||= Client.new(API_URL)
      end

      def global_installer
        @global_installer ||= MicroCommands::InstallGlobal.new(self.class.global_dir)
      end

      def assure_globally_installed
        global_installer.run :up unless global_installer.done?
      end
    end
  end
end

