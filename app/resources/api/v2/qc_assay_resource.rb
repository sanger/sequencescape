# frozen_string_literal: true

module Api
  module V2
    # QCAssayResource
    class QcAssayResource < JSONAPI::Resource
      attribute :lot_number
      attribute :qc_results

      has_many :qc_results
    end
  end
end
