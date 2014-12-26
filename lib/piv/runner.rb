module Piv

  class Runner < ::Thor

    option :force, :aliases => :f,
                   :default => false,
                   :type => :boolean,
                   :desc => <<-DESC.strip_heredoc
    Do not confirm.
                   DESC

    desc 'logout', 'Terminate current session'
    def logout
      Application.for(self, :logout) do
        if session_in_progress?
          confirm_logout unless options[:force]
          say "Terminated #{current_session.username}'s session", :green
          current_session.destroy
          exit 0
        else
          warn "no session in progress."
          exit 1
        end
      end
    end

    desc 'login', 'Log into pivotaltracker.com'
    def login
      Application.for(self, :login) do
        if session_in_progress? and user_wants_to_preserve_session?
          exit(0)
        end

        user, password = ask_for_credentials

        response = client.login(:user => user, :password => password)

        case response.status
        when 200
          body = response.body

          token, name     = body['api_token'], body['name']
          email, username = body['email'],     body['username']
          initials        = body['initials']

          Session.start(:token => token,
            :username => username,
            :name => name,
            :email => email,
            :initials => initials)

          say "You have been authenticated.", :green
          exit(0)
        else
          warn set_color(response.body['error'], :red)
          exit(1)
        end
      end
    end

    option :format, :type => :string,
                    :default => '%u',
                    :required => true,
                    :desc => <<-DESC.strip_heredoc
    Format to use when printing current user information:
      available options are:
        %n => user's name
        %u => user's email or username
    DESC

    desc 'whoami', 'Print current session information'
    def whoami
      Application.for(self, :whoami) do
        if session_in_progress?
          say parse_format(options[:format], current_session.attributes)
        else
          warn "no session in progress."
        end

        exit 0
      end
    end

  end
end
