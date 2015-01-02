module Piv
  module Helpers
    module Shell

      def more(text, flags=[:R],overwrites={})
        out = overwrites[:out] || STDOUT
        err = overwrites[:err] || STDERR

        read, write = pipes = IO.pipe

        text.display(write)

        flags = flags.any? ? "-" + flags.join : ''
        pid = spawn("more #{flags}", :in => read, :out => out, :err => err)

        pipes.each(&:close)

        Process.wait pid
      end

    end
  end
end
