# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for Plate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PlatesController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
      # API endpoint for registering stock for a plate
      # This endpoint allows the registration of stock for a plate by its ID.
      # It retrieves the plate by its ID, checks if it exists, and then registers stock for all wells with contents.
      # If the plate is not found, it returns a 404 error with a message.
      # If the stock registration fails, it returns a 422 error with the error message.
      # @param id [String] The ID of the plate for which stock needs to be registered.
      # @return [JSON] A JSON response indicating the success or failure of the stock registration.
      def register_stock_for_plate
        plate = Plate.find_by(id: params[:id])

        return render json: { error: 'Plate not found' }, status: :not_found if plate.blank?

        begin
          plate.wells.with_contents.each(&:register_stock!)
          render json: { message: 'Stock successfully registered for plate wells' }, status: :ok
        rescue StandardError => e
          render json: { error: "Stock registration failed: #{e.message}" }, status: :unprocessable_entity
        end
      end
    end
  end
end
