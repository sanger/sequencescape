# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TagSet}, which links together two related tag groups.
    # A TagSet represents a logical grouping of tags used for indexing in sequencing experiments.
    # It typically consists of a primary tag group and an optional secondary tag group,
    # enabling support for both single and dual indexing workflows.
    # This resource allows clients to query, filter, and retrieve information about tag sets,
    # including their associated tag groups and metadata, through the `/api/v2/tag_sets/` endpoint.
    #
    # @note Access this resource via the `/api/v2/tag_sets/` endpoint.
    #
    # @example GET request for all TagSet resources
    #   GET /api/v2/tag_sets/
    #
    # @example GET request for a specific TagSet by ID
    #   GET /api/v2/tag_sets/123/
    #
    # @example Filtering by tag group adapter type name
    #   GET /api/v2/tag_sets/?filter[tag_group_adapter_type_name]=AdapterType1
    #
    # @example Filtering by visibility (applied by default)
    #   GET /api/v2/tag_sets/?filter[visible]=true
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package, which implements JSON:API for Sequencescape.
    class TagSetResource < BaseResource
      immutable

      default_includes :uuid_object, :tag_group, :tag2_group

      ###
      # Relationships
      ###

      # @!attribute [r] tag_group
      #   A relationship for the primary tag group associated with the tag layout template.
      #   @return [Api::V2::TagGroupResource]
      has_one :tag_group, readonly: true

      # @!attribute [r] tag2_group
      #   A relationship for the secondary tag group associated with the tag layout template.
      #   This is used during dual indexing, but will not be found during single indexing.
      #   @return [Api::V2::TagGroupResource]
      has_one :tag2_group, readonly: true

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The UUID of the tag set.
      #   @return [String].
      attribute :uuid, readonly: true

      # @!attribute [r] name
      #   The display name of the tag set.
      #   @return [String]
      attribute :name, readonly: true

      ###
      # Filters
      ###

      # Allows filtering by the adapter type name of the tag group.
      # @example
      #   GET /api/v2/tag_sets/?filter[tag_group_adapter_type_name]=AdapterType1
      filter :tag_group_adapter_type_name, apply: ->(records, value, _options) { records.by_adapter_type(value) }

      # Allows filtering by visibility.
      # @example
      #   GET /api/v2/tag_sets/?filter[visible]=true
      filter :visible, default: true, apply: ->(records, _value, _options) { records.visible }
    end
  end
end
