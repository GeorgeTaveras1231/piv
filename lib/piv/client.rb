module Piv
  class Client
    class NetworkError < StandardError; end

    def initialize(connection, &config)
      @connection = connection
      @config = config || Proc.new {}
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

    def path(name)
      @connection.path_prefix + name
    end

    def login_request(credentials)
      credentials.assert_valid_keys :user, :password
      @connection.basic_auth(credentials[:user], credentials[:password])
      @connection.get(path('/me'), &@config)
    end

    def projects_request(params)
      params.assert_valid_keys :token, :account_ids
      @connection.get(path('/projects')) do |req|
        req.headers['X-Trackertoken'] = params[:token]
        req.params[:account_ids] = params[:account_ids] if params[:account_ids]
        @config.call(req)
      end
    end
  end
end
