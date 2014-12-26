module Piv
  class Client
    class NetworkError < StandardError; end

    def initialize(connection, &config)
      @connection = connection
      @config = config || -> {}
    end

    def method_missing(meth, *args)
      desired_method = "#{meth}_request"
      if self.private_methods.include? desired_method.to_sym
        begin
          send(desired_method, *args)
        rescue Faraday::TimeoutError, Faraday::ClientError => e
          msg = case e
                when Faraday::TimeoutError
                  "the request timed out"
                when Faraday::ClientError
                  "the connection failed"
                end

          raise NetworkError, msg
        end
      else
        super
      end
    end

    private

    def login_request(credentials)
      credentials.assert_valid_keys :user, :password
      @connection.basic_auth(credentials[:user], credentials[:password])
      @connection.get(@connection.path_prefix + '/me', &@config)
    end
  end
end
