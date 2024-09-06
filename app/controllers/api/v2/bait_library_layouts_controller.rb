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
      #   No `id` is included as this is a preview and not a persisted record.
      def preview
        records = preview_records
        return if records.nil?

        # Catch the layout preview failing validation.
        begin
          preview = BaitLibraryLayout.preview!(user: records[:user], plate: records[:plate])
        rescue ActiveRecord::RecordInvalid => e
          respond_with_errors('Validation failed', e.record.errors.full_messages, :unprocessable_entity) and return
        end

        json = { data: { type: 'bait_library_layouts', attributes: { layout: preview.layout } } }
        render json: json, status: :ok
      end

      private

      def respond_with_errors(title, details, status)
        status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]

        errors = details.map { |detail| { title: title, detail: detail, code: status_code, status: status_code } }

        render json: { errors: errors }, status: status
      end

      def preview_params
        params.permit(:user_uuid, :plate_uuid)
      end

      def preview_user(record_errors)
        user_uuid = preview_params.require(:user_uuid)
        user = User.with_uuid(user_uuid).first
        record_errors.append("The User record identified by UUID '#{user_uuid}' cannot be found") if user.nil?

        user
      end

      def preview_plate(record_errors)
        plate_uuid = preview_params.require(:plate_uuid)
        plate = Plate.with_uuid(plate_uuid).first
        record_errors.append("The Plate record identified by UUID '#{plate_uuid}' cannot be found") if plate.nil?

        plate
      end

      def preview_records
        begin
          record_errors = []
          user = preview_user(record_errors)
          plate = preview_plate(record_errors)
        rescue ActionController::ParameterMissing => e
          respond_with_errors('Missing parameter', [e.message], :bad_request) and return
        end

        respond_with_errors('Record not found', record_errors, :bad_request) and return if record_errors.any?

        { user: user, plate: plate }
      end
    end
  end
end
