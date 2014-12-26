module Piv
  module Helpers
    module Login
      def user_wants_to_preserve_session?
        not yes? <<-MSG.strip_heredoc
#{current_session.username} has already established a session, do you want to start a new session?#{set_color('[yYnN]', nil, :bold)}
        MSG
      end

      def ask_for_credentials
        user = ask "User: ", :add_to_history => true
        password = ask "Password: ", :echo => false
        puts "\n"
        [user, password]
      end
    end
  end
end
