# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for Plate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PlatesController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
      def register_stock_for_plate
        plate = Plate.find_by_id(params[:id])

        if plate.blank?
          return render json: { error: 'Plate not found' }, status: :not_found
        end
       
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
