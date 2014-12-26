module Piv
  module Helpers
    module Logout
      def confirm_logout
        unless yes? "Are you sure you want to log #{current_session.user} out? #{set_color('[yYnN]', nil, :bold)}"
          exit 0
        end
      end
    end
  end
end
