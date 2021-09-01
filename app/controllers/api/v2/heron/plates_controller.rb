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
          if factory.valid? && factory.save
            render json: {
                     data: {
                       attributes: {
                         uuid: factory.plate.uuid,
                         purpose_name: factory.purpose.name,
                         study_names: factory.sample_study_names
                       },
                       links: {
                         self: api_v2_plate_url(factory.plate)
                       }
                     }
                   },
                   status: :created
          else
            render json: { errors: factory.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def params_for_plate
          params
            .require(:data)
            .require(:attributes)
            .permit(:barcode, :purpose_uuid, :study_uuid, events: [{ event: {} }], wells: {})
        end
      end
    end
  end
end
