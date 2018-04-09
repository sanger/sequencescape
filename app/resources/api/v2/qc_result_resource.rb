# frozen_string_literal: true

module Api
  module V2
    # QCResultResource
    class QcResultResource < JSONAPI::Resource
      attributes :key, :value, :units, :cv, :assay_type, :assay_version

      has_one :asset
    end
  end
end
