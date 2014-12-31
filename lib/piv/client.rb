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

    def projects_request(params = {})
      params.assert_valid_keys :account_ids
      @connection.get(path('/projects'), params, &@config)
    end

    def stories_request(params)
      params.assert_valid_keys :project_id,
        :with_label,
        :with_state,
        :after_story_id,
        :before_story_id,
        :accepted_before,
        :accepted_after,
        :created_before,
        :created_after,
        :updated_before,
        :updated_after,
        :deadline_before,
        :limit,
        :offset,
        :fitler

      project_id = params.delete(:project_id) do
        raise ArgumentError, ':project_id is a required parameter'
      end

      stories_path = "projects/#{project_id}/stories"

      @connection.get(path(stories_path), params, &@config)
    end
  end
end
