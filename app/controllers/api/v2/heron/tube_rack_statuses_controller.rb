# frozen_string_literal: true

module Api
  module V2
    module Heron
      # Endpoint to create TubeRackStatuses
      class TubeRackStatusesController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          tube_rack_status_factory = ::Heron::Factories::TubeRackStatus.new(tube_rack_status_params)
          if tube_rack_status_factory.save
            render json: {}, status: :created
          else
            render json: { errors: tube_rack_status_factory.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def tube_rack_status_params
          params.require(:data)
                .require(:attributes)
                .require(:tube_rack_status)
                .require(:tube_rack)
                .permit(:barcode, :status, messages: [])
        end
      end
    end
  end
end
