# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/tag_groups/` endpoint.
    #
    # Provides a JSON:API representation of {TagGroup}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TagGroupResource < BaseResource
      # Constants...

      # model_name / model_hint if required

      default_includes :uuid_object, :tags

      # Associations:
      has_one :tag_group_adapter_type,
              foreign_key: :adapter_type_id,
              write_once: true,
              class_name: 'TagGroupAdapterType'

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, write_once: true
      attribute :tags, write_once: true

      # Filters
      filter :visible, default: true
      filter :name
      filter :tag_group_adapter_type_name, apply: ->(records, value, _options) { records.by_adapter_type(value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
      # We inline tags to better isolate our implementation
      def tags
        _model.tags.sort_by(&:map_id).map { |tag| { index: tag.map_id, oligo: tag.oligo } }
      end
    end
  end
end
