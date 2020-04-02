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
          if rack_factory.save
            render json: {}, status: :created
          else
            render json: { errors: rack_factory.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def params_for_tube_rack
          params.require(:data).require(:attributes).require(:tube_rack).permit(:barcode, :size, tubes: %i[barcode supplier_sample_id coordinate])
        end
      end
    end
  end
end
