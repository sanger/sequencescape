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
          render_unauthorized
        end
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

      def log_request_without_key
        puts 'No API key given'
      end
    end
  end
end
