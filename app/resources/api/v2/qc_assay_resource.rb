# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of QC Assay
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class QcAssayResource < BaseResource
      attribute :lot_number
      attribute :qc_results

      has_many :qc_results
    end
  end
end
