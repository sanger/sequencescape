# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/qc_results/` endpoint.
    #
    # Provides a JSON:API representation of {QcResult}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class QcResultResource < BaseResource
      attributes :key, :value, :units, :cv, :assay_type, :assay_version

      # We expose created at to allow us to find the most recent
      # measurement
      attribute :created_at, readonly: true

      has_one :asset
    end
  end
end
