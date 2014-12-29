module Piv

  class Runner < ::Thor
    desc 'projects [COMMAND]', 'Manage projects'
    subcommand :projects, Subcommands::Projects

    option :force, :aliases => :f,
                   :default => false,
                   :type => :boolean,
                   :desc => <<-DESC.strip_heredoc
                    Do not confirm.
                   DESC

    desc 'logout', 'Terminate current session'
    def logout
      Application.for(self, :logout) do
        requires_active_session!

        confirm_logout unless options[:force]
        say "Terminated #{current_session.username}'s session", :green
        current_session.destroy

        exit 0
      end
    end

    desc 'login', 'Log into pivotaltracker.com'
    def login
      Application.for(self, :login) do
        if session_in_progress? and user_wants_to_preserve_session?
          exit 0
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
    Format to use when printing current user information.
      Available meta-characters are:
        %n => name
        %u => username
        %i => initials
        %e => email

        %c => shell colors with Thor color helpers eg: "%c(bold green on_magenta) I am colorful "

    DESC

    desc 'whoami', 'Print current session information'
    def whoami
      Application.for(self, :formatter, :whoami) do
        requires_active_session!
        print_formatted_model(current_session)

        exit 0
      end
    end

  end
end
