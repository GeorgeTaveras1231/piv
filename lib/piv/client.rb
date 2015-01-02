module Piv
  class Client
    class NetworkError < StandardError; end

    def initialize(connection, &config)
      @connection = connection
      @config = config || Proc.new {}
    end

    def iterations(params)
      params.assert_valid_keys :project_id,
        :offset,
        :label,
        :limit,
        :scope

      project_id = params.delete(:project_id) do
        raise ArgumentError, ':project_id is a required key'
      end

      iterations_path = "projects/#{project_id}/iterations"
      dispatch(:get, iterations_path, params)
    end

    def login(credentials)
      credentials.assert_valid_keys :user, :password
      @connection.basic_auth(credentials[:user], credentials[:password])
      dispatch(:get, '/me')
    end

    def projects(params = {})
      params.assert_valid_keys :account_ids
      dispatch(:get, '/projects', params)
    end

    def stories(params)
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
        raise ArgumentError, ':project_id is a required key'
      end

      stories_path = "projects/#{project_id}/stories"

      dispatch(:get, stories_path, params)
    end

    private

    def dispatch(req_method, path_name, *args, &block)
      unless %w( get post patch put ).include?(req_method.to_s)
        raise ArgumentError, "#{req_method} is not a request method"
      end

      @connection.send(req_method, path(path_name), *args) do |req|
        @config.call(req)
        block.call(req) if block_given?
      end
    rescue Exception => e
      msg = case e
            when Faraday::TimeoutError
              "the request timed out"
            when Faraday::ClientError
              "the connection failed"
            end

      if msg
        raise NetwordError, msg
      else
        raise e
      end
    end

    def path(name)
      File.join(@connection.path_prefix, name)
    end
  end
end
