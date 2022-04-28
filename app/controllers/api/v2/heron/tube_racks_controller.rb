# frozen_string_literal: true

module Api
  module V2
    module Heron
      # Endpoint to create TubeRacks inside Sequencescape for Heron
      class TubeRacksController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          rack_factory = ::Heron::Factories::TubeRack.new(params_for_tube_rack)
          if rack_factory.valid? && rack_factory.save
            render json: {
                     data: {
                       attributes: {
                         uuid: rack_factory.tube_rack.uuid,
                         purpose_name: rack_factory.purpose.name,
                         study_names: rack_factory.sample_study_names
                       },
                       links: {
                         self: api_v2_tube_rack_url(rack_factory.tube_rack)
                       }
                     }
                   },
                   status: :created
          else
            render json: { errors: rack_factory.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def params_for_tube_rack
          params.require(:data).require(:attributes).permit(:barcode, :study_uuid, :purpose_uuid, tubes: {})
        end
      end
    end
  end
end
