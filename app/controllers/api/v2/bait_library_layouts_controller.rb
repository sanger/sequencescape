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
      #
      # @example Preview a {BaitLibraryLayout} with the given User and Plate identified by UUIDs
      #   POST /api/v2/bait_library_layouts/preview
      #   {
      #     "user_uuid": "11111111-2222-3333-4444-555555666666",
      #     "plate_uuid": "22222222-3333-4444-5555-666666777777"
      #   }
      #
      # @return [JSON] The JSON representation of a sparsely populated {BaitLibraryLayoutResource}.
      #   Only the `layout` attribute is included.
      #   The returned `id` is always `0` and cannot be used to reference the resource.
      def preview
        records = preview_records
        return if records.nil?

        # Catch the layout preview failing validation.
        begin
          preview = BaitLibraryLayout.preview!(user: records[:user], plate: records[:plate])
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity and return
        end

        json = { data: { id: 0, type: 'bait_library_layouts', attributes: { layout: preview.layout } } }
        render json: json, status: :ok
      end

      private

      def preview_params
        params.permit(:user_uuid, :plate_uuid)
      end

      def preview_records
        # Catch missing required parameters.
        begin
          missing_records_errors = []

          user = User.with_uuid(preview_params.require(:user_uuid)).first
          missing_records_errors.append('User not found') if user.nil?

          plate = Plate.with_uuid(preview_params.require(:plate_uuid)).first
          missing_records_errors.append('Plate not found') if plate.nil?
        rescue ActionController::ParameterMissing => e
          render json: { errors: [e.message] }, status: :bad_request and return
        end

        render json: { errors: missing_records_errors }, status: :bad_request and return if missing_records_errors.any?

        { user: user, plate: plate }
      end
    end
  end
end
