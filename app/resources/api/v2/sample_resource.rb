# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/samples/` endpoint.
    #
    # Provides a JSON:API representation of {Sample}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SampleResource < BaseResource
      has_one :sample_metadata, class_name: 'SampleMetadata', foreign_key_on: :related
      has_one :sample_manifest

      has_many :studies
      has_many :component_samples

      attribute :name
      attribute :sanger_sample_id
      attribute :uuid, readonly: true
      attribute :control
      attribute :control_type

      # Filters
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :sanger_sample_id
      filter :name
    end
  end
end
