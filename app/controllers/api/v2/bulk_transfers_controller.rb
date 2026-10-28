# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for Bulk Transfers.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
    class BulkTransfersController < JSONAPI::ResourceController
      private

      # Added to handle Aliquot::TagClash exceptions specifically.
      # This ensures that when a tag clash occurs, a proper JSONAPI error response is returned.
      def handle_exceptions(exception)
        return super unless exception.is_a?(Aliquot::TagClash)

        render_errors(
          [
            JSONAPI::Error.new(
              status: :unprocessable_content,
              code: 'tag_clash',
              title: 'Tag clash',
              detail: exception.message
            )
          ]
        )
      end
    end
  end
end
