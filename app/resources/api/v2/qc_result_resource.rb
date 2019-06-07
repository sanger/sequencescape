# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of QC Result
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class QcResultResource < BaseResource
      attributes :key, :value, :units, :cv, :assay_type, :assay_version

      # We expose created at to allow us to find the most recent
      # measurement
      attribute :created_at, readonly: true

      has_one :asset
    end
  end
end
