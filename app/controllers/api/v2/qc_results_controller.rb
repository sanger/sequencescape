# frozen_string_literal: true

module Api
  module V2
    # QcResultsController
    # create needs some specific code as it is not standard JSON API behaviour
    class QcResultsController < JSONAPI::ResourceController
      def create
        @qc_result_factory = QcResultFactory.new(qc_results_params)
        if @qc_result_factory.valid?
          @qc_result_factory.save
          @qc_result_resources = @qc_result_factory.qc_results.map { |qc_result| QcResultResource.new(qc_result, nil) }
          render json: JSONAPI::ResourceSerializer.new(QcResultResource).serialize_to_hash(@qc_result_resources), status: :created
        else
          render json: @qc_result_factory.errors, status: :unprocessable_entity
        end
      end

      def qc_results_params
        params.require(:data).require(:attributes).map do |p|
          ActionController::Parameters.new(p.to_unsafe_h).permit(:uuid, :well_location, :key, :value, :units, :cv, :assay_type, :assay_version)
        end
      end
    end
  end
end
