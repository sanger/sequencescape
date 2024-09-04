# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for BaitLibraryLayouts
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaitLibraryLayoutsController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard behaviour, and in many cases this file may be
      # left empty.
      # However, to remain consistent with functionality of API v1, we have included a custom preview method here.

      # Preview the layout of the bait libraries on a plate.
      # This method is not part of the JSONAPI::ResourceController standard actions.
      # @example Preview a {BaitLibraryLayout} with the given User and Plate identified by UUIDs
      #   POST /api/v2/bait_library_layouts/preview
      #   {
      #     "user_uuid": "11111111-2222-3333-4444-555555666666",
      #     "plate_uuid": "22222222-3333-4444-5555-666666777777"
      #   }
      # @return [JSON] The JSON representation of a {BaitLibraryLayout}.
      def preview
        temp_response = {
          data: {
            id: 0,
            type: 'bait_library_layouts',
            attributes: {
              layout: {
                'Human all exon 50MB': %w[A1 A2]
              }
            }
          }
        }

        render json: temp_response, status: :ok
      end
    end
  end
end
