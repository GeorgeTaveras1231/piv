module Piv

  class CLI < Thor

    desc 'login', 'Log into pivotaltracker.com'
    def login
      Application.for(:login) do |a|

        a.assure_globally_installed

        if a.session_in_progress? and a.user_wants_to_preserve_session?
          exit(0)
        end

        user, password = a.ask_for_credentials

        response = a.client.login(:user => user, :password => password)

        case response.status
        when 200
          token, name = response.body['api_token'], response.body['name']

          session = Session.first_or_create(:token => token, :user => user, :name => name)

          session.current = true
          session.save

          say "You have been authenticated.", :green
          exit(0)
        else
          warn set_color(response.body['error'], :red)
          exit(1)
        end
      end

    rescue Client::NetworkError => e
      warn set_color(e.message, :red)
      exit(1)
    end

    desc 'whoami', 'Print current user'
    def whoami
      Application.for(:login) do |a|
        a.assure_globally_installed
        puts Session.current.name
      end
    end
  end
end
