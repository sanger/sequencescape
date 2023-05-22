module Api
  module V2
    module ApiKeyAuthenticatable
      extend ActiveSupport::Concern

      def authenticate_with_api_key
        render status: :unauthorized,
               json: {
                 error: 'You are not authorized to access this resource. Please ensure a valid API key is provided.'
               } and return
      end
    end
  end
end
