# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/studies/` endpoint.
    #
    # Provides a JSON:API representation of {Study}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class StudyResource < BaseResource
      immutable

      attribute :name
      attribute :uuid

      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'

      filter :name

      filter :state, apply: lambda { |records, value, _options| records.by_state(value) }

      filter :user, apply: lambda { |records, value, _options| records.by_user(value) }
    end
  end
end
