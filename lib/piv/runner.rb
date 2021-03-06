module Piv

  ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['AR_LOG']

  class Runner < ::Thor
    desc 'stories [COMMAND]', 'Manage stories'
    subcommand :stories, Subcommands::Stories

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
          initials, id    = body['initials'],  body['id']

          Session.start(:id => id.to_s,
            :token => token,
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
                    :default => '%a( username )',
                    :required => true

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
