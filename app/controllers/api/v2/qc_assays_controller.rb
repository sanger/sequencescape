# frozen_string_literal: true

module Api
  module V2
    # QcAssaysController
    class QcAssaysController < JSONAPI::ResourceController
      def create
        @qc_result_factory = QcResultFactory.new(qc_assay_params)
        if @qc_result_factory.valid?
          @qc_result_factory.save

          render json: serialize_resource(QcAssayResource.new(@qc_result_factory.qc_assay, nil)), status: :created
        else
          render json: { errors: @qc_result_factory.errors }, status: :unprocessable_entity
        end
      end

      def qc_assay_params
        params
          .require(:data)
          .require(:attributes)
          .permit(:lot_number, qc_results: %i[barcode uuid well_location key value units cv assay_type assay_version])
      end
    end
  end
end
