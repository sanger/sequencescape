# frozen_string_literal: true

module Api
  module V2
    module Bioscan
      # Endpoint to export a PoolXP tube to Traction
      class ExportPoolXpToTractionController < ApplicationController
        before_action :login_required, except: [:create]
        skip_before_action :verify_authenticity_token

        def create
          Rails.logger.debug "DEBUG: In ExportPoolXpToTractionController create"
          # TODO: do we need to check the tube barcode is valid here?
          Delayed::Job.enqueue ExportPoolXpToTractionJob.new(barcode)
          # TODO: check if job queuing was successful or not and return appropriate status
          # TODO: how to know if job successfully queued?
          # TODO: does rendering something here send something back to Limber?
          # if successful
          render json: {}, status: :created
          # else
          #   render json: { errors: ?.errors.full_messages }, status: :unprocessable_entity
          # end
        end

        private

        def attributes
          params.require(:data).require(:attributes).permit(:barcode)
        end

        def barcode
          attributes.require(:barcode)
        end
      end
    end
  end
end
