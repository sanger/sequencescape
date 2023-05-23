module Api
  module V2
    module ApiKeyAuthenticatable
      extend ActiveSupport::Concern

      def authenticate_with_api_key
        if request.env.key? @http_env_api_key
          validate_api_key request.env[@http_env_api_key]
        else
          log_request_without_key
        end
      end

      private

      attr_reader :http_env_api_key

      def initialize
        @http_env_api_key = 'HTTP_X_SEQUENCESCAPE_CLIENT_ID'
      end

      def validate_api_key(api_key)
        begin
          api_application = ApiApplication.find_by!(key: api_key)
        rescue ActiveRecord::RecordNotFound => exception
          render_unauthorized api_key
        end
      end

      def render_unauthorized(api_key)
        request_log = {
          utc_time: Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%L'),
          remote_ip: request.remote_ip,
          user_agent: request.env['HTTP_USER_AGENT'],
          api_key: api_key,
          origin: request.env['HTTP_ORIGIN'],
          original_url: request.original_url,
          request_method: request.request_method
        }

        Rails.logger.info("Request made with invalid API key: #{request_log}")

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

      def log_request_without_key
        request_log = {
          utc_time: Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%L'),
          remote_ip: request.remote_ip,
          user_agent: request.env['HTTP_USER_AGENT'],
          origin: request.env['HTTP_ORIGIN'],
          original_url: request.original_url,
          request_method: request.request_method
        }

        Rails.logger.info("Request made without an API key: #{request_log}")
      end
    end
  end
end
