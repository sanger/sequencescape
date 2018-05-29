# frozen_string_literal: true

module Api
  module V2
    # QCResultResource
    class QcResultResource < JSONAPI::Resource
      attributes :key, :value, :units, :cv, :assay_type, :assay_version

      # We expose created at to allow us to find the most recent
      # measurement
      attribute :created_at, readonly: true

      has_one :asset
    end
  end
end
