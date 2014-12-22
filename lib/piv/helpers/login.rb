module Piv
  module Helpers
    module Login
      def user_wants_to_preserve_session?(istream = $stdin, ostream = $stdout)
        msg = "#{current_session.name} has already established a session,\
        do you want to start a new session?\e[1m[yN]\e[0m "
        ostream.print msg.squeeze(' ')
        istream.gets.strip !~ /^y$/i
      end

      def ask_for_credentials(istream = $stdin, ostream = $stdout)
        ostream.print "User: "
        user = istream.gets.strip
        ostream.print "Password: "
        password = istream.noecho(&:gets).strip
        puts "\n"

        [user, password]
      end
    end
  end
end
