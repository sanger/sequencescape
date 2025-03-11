# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of the {TagLayout} resource.
    #
    # {TagLayout} Lays out the tags in the specified tag group in a particular pattern.
    # This resource is used for managing tag layouts for plates, which define how tags are applied or distributed across
    # the plate. It supports creating a tag layout and retrieving its details.
    #
    # @note Access this resource via the `/api/v2/tag_layouts/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example GET request to fetch all tag layouts
    #   GET /api/v2/tag_layouts/
    #
    # @example GET request to fetch a specific tag layout by ID
    #   GET /api/v2/tag_layouts/123/
    #
    # @example POST request to create a new tag layout
    #   POST /api/v2/tag_layouts/
    # {
    #   "data": {
    #     "type": "tag_layouts",
    #     "attributes": {
    #         "direction": "column",
    #         "initial_tag": 100,
    #         "substitutions": {"key": "value"},
    #         "tags_per_well": 5,
    #         "walking_by": "wells in pools"
    #     },
    #     "relationships": {
    #         "tag_group": {
    #             "data": { "type": "tag_groups", "id": 1 }
    #         },
    #         "plate": {
    #             "data": { "type": "plates", "id": 1 }
    #         },
    #         "user": {
    #             "data": { "type": "users", "id": 4 }
    #         }
    #     }
    #   }
    # }
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TagLayoutResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] direction
      #   The name of the algorithm defining the direction of the tag layout.
      #   @return [String] The direction of the tag layout.
      #   @note This attribute is required and must be specified when creating a tag layout.
      attribute :direction

      # @!attribute [rw] initial_tag
      #   An offset for the tag set indicating which tag to start with in the layout.
      #   @return [Integer] The tag number to start with in the layout.
      attribute :initial_tag

      # @!attribute [w] plate_uuid
      #   This is a convenience attribute for when the plate is not available as a relationship.
      #   @deprecated Use the `plate` relationship instead.
      #   Setting this alongside the `plate` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the {Plate} this tag layout applies to.
      #   @return [Void]
      #   @see #plate
      attribute :plate_uuid, writeonly: true

      def plate_uuid=(value)
        @model.plate = Plate.with_uuid(value).first
      end

      # @!attribute [rw] substitutions
      #   A hash of substitutions to be applied during the layout creation, mapping placeholders to values.
      #   @return [Hash] The substitutions for the tag layout.
      attribute :substitutions

      def substitutions=(value)
        @model.substitutions =
          if value.is_a?(ActionController::Parameters)
            value.to_unsafe_h # We must unwrap the parameters to a real Hash.
          else
            value
          end
      end

      # @!attribute [w] tag_group_uuid
      #   This is a convenience attribute for when the {TagGroup} is not available to set as a relationship.
      #   @deprecated Use the `tag_group` relationship instead.
      #   Setting this alongside the `tag_group` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the {TagGroup} used in this tag layout.
      #   @return [Void]
      #   @see #tag_group
      attribute :tag_group_uuid, writeonly: true

      def tag_group_uuid=(value)
        @model.tag_group = TagGroup.with_uuid(value).first
      end

      # @!attribute [w] tag2_group_uuid
      #   This is a convenience attribute for when a second {TagGroup} is not available to set as a relationship.
      #   @deprecated Use the `tag2_group` relationship instead.
      #   Setting this alongside the `tag2_group` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the second {TagGroup} used in this tag layout.
      #   @return [Void]
      #   @see #tag2_group
      attribute :tag2_group_uuid, writeonly: true

      def tag2_group_uuid=(value)
        @model.tag2_group = TagGroup.with_uuid(value).first
      end

      # @!attribute [rw] tags_per_well
      #   The number of tags per well in the layout.
      #   Used for specific tag layout algorithms like {walking_by}.
      #   When not used, this will be `nil`.
      #   @return [Integer] The number of tags per well.
      attribute :tags_per_well

      # @!attribute [w] user_uuid
      #   This is a convenience attribute for when the {User} is not available to set as a relationship.
      #   @deprecated Use the `user` relationship instead.
      #   Setting this alongside the `user` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the {User} who initiated the creation of the tag layout.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the tag layout.
      attribute :uuid, readonly: true

      # @!attribute [rw] walking_by
      #   Defines the algorithm that determines how the tag layout is walked through (e.g., by row, by column).
      #   @return [String] The walking algorithm used for the tag layout.
      #   @note This attribute is required and must be specified when creating a tag layout.
      attribute :walking_by

      ###
      # Relationships
      ###

      # @!attribute [rw] plate
      #   This relationship defines the plate to which this tag layout is applied.
      #   Setting this relationship alongside the `plate_uuid` attribute will override the attribute value.
      #   @return [Api::V2::PlateResource] The plate resource associated with the tag layout.
      #   @note This relationship is required and must be set when creating the tag layout.
      has_one :plate

      # @!attribute [rw] tag_group
      #   Defines the primary tag group used in the tag layout.
      #   Setting this relationship alongside the `tag_group_uuid` attribute will override the attribute value.
      #   @return [Api::V2::TagGroupResource] The primary tag group for the tag layout.
      #   @note This relationship is required.
      has_one :tag_group

      # @!attribute [rw] tag2_group
      #   Defines a secondary tag group used in the tag layout, typically for dual indexing.
      #   Setting this relationship alongside the `tag2_group_uuid` attribute will override the attribute value.
      #   This is used during dual indexing, but will not be found during single indexing.
      #   @return [Api::V2::TagGroupResource] The secondary tag group for the tag layout.
      has_one :tag2_group, class_name: 'TagGroup'

      # @!attribute [rw] user
      #   Defines the user who initiated the creation of this tag layout.
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [Api::V2::UserResource] The user who initiated the creation.
      #   @note This relationship is required.
      has_one :user

      ###
      # Template Attributes
      ###

      # These are consumed by the TagLayoutProcessor and not a concern of the resource.
      # They are included here to allow their presence in the JSON:API request body and to document their use cases.

      # @!attribute [w] tag_layout_template_uuid
      #   @param value [String] the UUID of a TagLayoutTemplate to use for attributes of this TagLayout resource.
      #     Providing this UUID while also providing values for attributes and relationships which can be extracted from
      #     a {TagLayoutTemplateResource} will generate an error indicating that the UUID should not have been provided.
      #   @param value [String] The UUID of the template to apply to the tag layout.
      #   @note This attribute should not be provided if other attributes or relationships are set directly.
      attribute :tag_layout_template_uuid, writeonly: true
      attr_writer :tag_layout_template_uuid # Not stored on the model

      # @!attribute [w] enforce_uniqueness
      #   A flag indicating whether to set `enforce_uniqueness` on {TagLayout::TemplateSubmission}s when a template is
      #   used to create the TagLayout.
      #   @param value [Boolean] Whether to enforce uniqueness within template submissions.
      attribute :enforce_uniqueness, writeonly: true
      attr_writer :enforce_uniqueness # Not stored on the model
    end
  end
end
