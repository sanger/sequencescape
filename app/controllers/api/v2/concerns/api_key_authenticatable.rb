module Api
  module V2
    module ApiKeyAuthenticatable
      extend ActiveSupport::Concern

      def authenticate_with_api_key
        render_unauthorized
      end

      private

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
    end
  end
end
