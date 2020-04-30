# frozen_string_literal: true

module Api
  module V2
    module Heron
      # Endpoint to create Plates inside Sequencescape for Heron
      class PlatesController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          factory = ::Heron::Factories::Plate.new(params_for_plate)
          if factory.save
            render json: {}, status: :created
          else
            render json: { errors: factory.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def params_for_plate
          params.require(:data).require(:attributes).require(:plate).permit(:barcode, { wells_content: [] }, :plate_purpose_uuid, :study_uuid)
        end
      end
    end
  end
end
