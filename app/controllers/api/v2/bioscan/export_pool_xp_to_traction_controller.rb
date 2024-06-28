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

          errors = preflight_errors(barcode)
          render json: { errors: errors }, status: :unprocessable_entity and return unless errors.empty?

          Delayed::Job.enqueue ExportPoolXpToTractionJob.new(barcode)
          render json: {}, status: :ok
        end

        private

        def preflight_errors(barcode)
          # Check that the tube exists
          tube = Tube.find_by_barcode(barcode)
          return ["Tube with barcode '#{barcode}' not found"] if tube.nil?

          errors = []

          # Check that the tube has the correct purpose and state
          if tube.purpose.name != "LBSN-9216 Lib PCR Pool XP"
            errors << "Tube with barcode '#{barcode}' is not a Pool XP tube"
          end
          errors << "Tube with barcode '#{barcode}' is not in the 'passed' state" if tube.state != "passed"

          errors
        end

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
