# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TagGroup}
    # A {TagGroup} represents a set of {Tag tags} used in sequencing.
    #
    # A {Tag} is a short, know sequence of DNA which gets applied to a sample.
    # The tag remains attached through subsequent processing, and means that it is
    # possible to identify the origin of a sample if multiple samples are subsequently
    # pooled together.
    #
    # @note Access this resource via the `/api/v2/tag_groups/` endpoint.
    #
    # @example GET request for all tag groups
    #   GET /api/v2/tag_groups/
    #
    # @example GET request for a specific tag group by ID
    #   GET /api/v2/tag_groups/123/
    #
    # @todo The below POST example is provided for reference, however it currently throws an error.
    # This is because the example format of the `tags` attribute are not permitted.
    #
    # @example POST request to create a new tag group
    #   POST /api/v2/tag_groups/
    #   {
    #     "data": {
    #       "type": "tag_groups",
    #       "attributes": {
    #         "name": "My Tag Group",
    #         "tags": [
    #           { "map_id": 1,"oligo": "AAACGGCG"},
    #           { "map_id": 2,"oligo": "CAACGGCG"}
    #         ]
    #       },
    #       "relationships": {
    #         "tag_group_adapter_type": {
    #           "data": { "type": "tag_group_adapter_types", "id": 5 }
    #         }
    #       }
    #     }
    #   }
    #
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to [JSONAPI::Resources](http://jsonapi-resources.com/) for Sequencescape's implementation.
    class TagGroupResource < BaseResource
      default_includes :uuid_object, :tags

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the tag group.
      attribute :uuid, readonly: true

      # @!attribute [rw] name
      #   The name of the tag group.
      #   This attribute is required when creating a new tag group.
      #   @return [String] The name of the tag group.
      attribute :name, write_once: true

      # @!attribute [rw] tags
      #   A list of tags within the tag group.
      #   @return [Array<Hash>] The list of tag mappings within this tag group.
      attribute :tags, write_once: true

      ###
      # Relationships
      ###

      # @!attribute [rw] tag_group_adapter_type
      #   The adapter type associated with this tag group.
      #   This defines how the tags are used within a sequencing workflow.
      #   @return [TagGroupAdapterTypeResource] The adapter type of the tag group.
      #   @note This relationship is required
      has_one :tag_group_adapter_type,
              foreign_key: :adapter_type_id,
              write_once: true,
              class_name: 'TagGroupAdapterType'

      ###
      # Filters
      ###

      # @!method filter_by_visible
      #   @example Retrieve only visible tag groups
      #     GET /api/v2/tag_groups?filter[visible]=true
      #   @return [Boolean] Filters tag groups based on visibility.
      filter :visible, default: true

      # @!method filter_by_name
      #   @example Retrieve tag groups with a specific name
      #     GET /api/v2/tag_groups?filter[name]=MyTagGroup
      #   @return [String] Filters tag groups by their name.
      filter :name

      # @!method filter_by_tag_group_adapter_type_name
      #   @example Retrieve tag groups associated with a specific adapter type
      #     GET /api/v2/tag_groups?filter[tag_group_adapter_type_name]=Illumina
      #   @return [String] Filters tag groups by their adapter type name.
      filter :tag_group_adapter_type_name, apply: ->(records, value, _options) { records.by_adapter_type(value) }

      ###
      # Custom Methods
      ###

      # Returns the list of tags sorted by their index.
      #
      # @return [Array<Hash>] The list of tags, each with an index and an oligo sequence.
      def tags
        _model.tags.sort_by(&:map_id).map { |tag| { index: tag.map_id, oligo: tag.oligo } }
      end
    end
  end
end
