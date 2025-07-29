# frozen_string_literal: true
module Api
  module V2
    module Concerns
      # Provides the tools needed to confirm that a valid API key was provided for the header X-Sequencescape-Client-Id.
      # - Skips the check if the endpoint specifies permissve GETs
      # - Where the API key is in the request and exists in among ApiApplication, allow the request to be served.
      # - Where the API key is in the request but does not exist, log the attempt and render an unauthorized response.
      # - Where the API key is not in the request, respond normally (for now) and log the system that made the request.
      module ApiKeyAuthenticatable
        extend ActiveSupport::Concern

        included { prepend_before_action :authenticate_with_api_key }

        def authenticate_with_api_key
          # Check if the route requires an API key
          return if permissive_route

          http_env_api_key = 'HTTP_X_SEQUENCESCAPE_CLIENT_ID'

          if request.env.key? http_env_api_key
            validate_api_key request.env[http_env_api_key]
          else
            log_request_without_key
          end
        end

        private

        def validate_api_key(api_key)
          ApiApplication.find_by!(key: api_key)
        rescue ActiveRecord::RecordNotFound
          log_invalid_api_key api_key
          render_unauthorized
        end

        def request_log
          {
            utc_time: Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%L'),
            remote_ip: request.remote_ip,
            user_agent: request.env['HTTP_USER_AGENT'],
            origin: request.env['HTTP_ORIGIN'],
            original_url: request.original_url,
            request_method: request.request_method
          }
        end

        def log_request_without_key
          Rails.logger.info("Request made without an API key: #{request_log}")
        end

        def log_invalid_api_key(api_key)
          log_context = request_log
          log_context[:api_key] = api_key

          Rails.logger.info("Request made with invalid API key: #{log_context}")
        end

        def render_unauthorized
          render status: :unauthorized,
                 json: {
                   errors: [
                     {
                       title: 'Unauthorized.',
                       detail: "Please ensure a valid API key is provided for header 'X-Sequencescape-Client-Id'.",
                       code: '401',
                       status: '401'
                     }
                   ]
                 } and return
        end

        # Checks if the current request is a permissive route.
        #
        # A route is considered permissive if the 'permissive' path parameter is present in the request
        # and the HTTP request method is 'GET'.
        # Path parameters are defined next to the route in routes.rb e.g. jsonapi_resources :samples, permissive: true
        #
        # @return [Boolean] true if the route is permissive, false otherwise.
        def permissive_route
          # Use path_parameters as standard parameters are overridable by requesters
          request.path_parameters.fetch(:permissive, false) && request.get?
        end
      end
    end
  end
end
