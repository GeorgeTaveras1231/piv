module Piv
  module MicroCommands
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
  end
end
