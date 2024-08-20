# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/tag_sets/` endpoint.
    #
    # Provides a JSON:API representation of {TagGroup}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TagSetResource < BaseResource
      # Associations
      has_one :tag_group
      has_one :tag2_group, class_name: 'TagGroup'

      # Attributes
      attribute :name, readonly: true

      # Filters
      filter :name
    end
  end
end
