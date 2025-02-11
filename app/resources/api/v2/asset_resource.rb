# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/assets/` endpoint.
    #
    # Provides a JSON:API representation of {Asset}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class AssetResource < BaseResource
      attributes :uuid

      has_one :custom_metadatum_collection
      has_many :comments, readonly: true

      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   records.joins('LEFT JOIN plate_purposes ON plate_purposes.id = assets.plate_purpose_id').where(
                     plate_purposes: {
                       name: value
                     }
                   )
                 end
               )
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
    end
  end
end
