module Piv
  class Client
    class NetworkError < StandardError; end

    def initialize(url)
      @connection = Faraday.new(url) do |c|
        c.adapter :em_http
        c.request :json
        c.response :json
      end
    end

    def login(credentials)
      credentials.assert_valid_keys :user, :password
      @connection.basic_auth(credentials[:user], credentials[:password])
      @connection.get(@connection.path_prefix + '/me')

    rescue Faraday::TimeoutError, Faraday::ClientError => e
      msg = case e
            when Faraday::TimeoutError
              "the request timed out"
            when Faraday::ClientError
              "the connection failed"
            end

      raise NetworkError, msg
    end
  end
end
