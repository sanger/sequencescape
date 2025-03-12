# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TagSet}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    #
    # This resource represents a TagSet, which links together two related tag groups.
    # It includes the following attributes and relationships:
    #
    # Attributes:
    # - uuid: The unique identifier for the TagSet.
    # - name: The name of the TagSet.
    #
    # Relationships:
    # - tag_group: The primary tag group associated with the TagSet.
    # - tag2_group: The secondary tag group associated with the TagSet (optional).
    #
    # Filters:
    # - tag_group_adapter_type_name: Filters TagSets by the adapter type name of the tag group.
    #
    # The resource also includes custom methods to determine the adapter type and to filter out
    # soft-deleted tag sets by checking the visibility of the tag groups.
    class TagSetResource < BaseResource
      default_includes :uuid_object, :tag_group, :tag2_group

      # Associations:

      # @!attribute [r] tag_group
      #   A relationship for the primary tag group associated with the tag layout template.
      #   @return [Api::V2::TagGroupResource]
      has_one :tag_group, readonly: true

      # @!attribute [r] tag2_group
      #   A relationship for the secondary tag group associated with the tag layout template.
      #   This is used during dual indexing, but will not be found during single indexing.
      #   @return [Api::V2::TagGroupResource]

      has_one :tag2_group, readonly: true

      # Attributes
      # @!attribute [r] uuid
      #   The UUID of the tag set.
      #   @return [String].
      attribute :uuid, readonly: true

      # @!attribute [r] name
      #   The display name of the tag set.
      #   @return [String]
      attribute :name, readonly: true

      # Filters
      filter :tag_group_adapter_type_name, apply: ->(records, value, _options) { records.by_adapter_type(value) }

      filter :visible, default: true, apply: ->(records, _value, _options) { records.visible }
    end
  end
end
