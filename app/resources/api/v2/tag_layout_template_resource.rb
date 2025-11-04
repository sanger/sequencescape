# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TagLayoutTemplate}
    #
    # This resource represents a {TagLayoutTemplate} which defines the layout and walking algorithm used
    #    during the indexing
    # of tags for labware or objects.
    # Think of it as a partially created TagLayout, defining only the tag
    # group that will be used and the actual TagLayout implementation that will do the work.
    #
    # This resource is read-only and can only be accessed via `GET` requests. It cannot be modified or deleted.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/tag_layout_templates/` endpoint.
    #
    # @example GET request for all TagLayoutTemplate resources
    #   GET /api/v2/tag_layout_templates/
    #
    # @example GET request for a TagLayoutTemplate with ID 123
    #   GET /api/v2/tag_layout_templates/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TagLayoutTemplateResource < BaseResource
      immutable

      ###
      # Relationships
      ###

      # @!attribute [r] tag_group
      #   The primary tag group associated with the tag layout template.
      #   This relationship represents the group of tags that the layout template is based on.
      #   @return [Api::V2::TagGroupResource] The tag group related to the tag layout template.
      #   @note This relationship is read-only.
      has_one :tag_group, readonly: true

      # @!attribute [r] tag2_group
      #   The secondary tag group associated with the tag layout template.
      #   This relationship is used during dual indexing, but will not be found during single indexing.
      #   @return [Api::V2::TagGroupResource] The secondary tag group used in the tag layout template.
      #   @note This relationship is read-only and may not be applicable during single indexing.
      has_one :tag2_group, class_name: 'TagGroup', readonly: true

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The unique identifier for the tag layout template.
      #   @return [String] The UUID of the tag layout template.
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      attribute :uuid, readonly: true

      # @!attribute [r] name
      #   The display name of the tag layout template.
      #   @return [String] The name given to the tag layout template.
      #   @note This attribute is read-only.
      attribute :name, readonly: true

      # @!attribute [r] direction
      #   The algorithm that defines the direction of the tag layout.
      #   This attribute specifies the walking direction during tag indexing.
      #   @return [String] The name of the algorithm defining the direction of the layout.
      #   @note This attribute is read-only.
      attribute :direction, readonly: true

      # @!attribute [r] walking_by
      #   The algorithm that defines the way of walking through the tag layout.
      #   This attribute specifies how the tags are indexed within the layout.
      #   @return [String] The name of the algorithm defining the walking method.
      #   @note This attribute is read-only.
      attribute :walking_by, readonly: true

      ###
      # Filters
      ###

      # @!method enabled
      #   Filter to return only enabled tag layout templates.
      #   This filter allows users to specify if only active tag layouts should be returned.
      #   @example Using the filter: `GET /api/v2/tag_layout_templates?enabled=true`
      #   @return [Boolean] Whether the tag layout template is enabled or not.
      filter :enabled, default: true

      # @!method uuid
      #   A filter to return only lots with the given UUID.
      #   @example Filtering lots by UUID
      #     GET /api/v2/lots?filter[uuid]=11111111-2222-3333-4444-555555666666
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(*value) }
    end
  end
end
