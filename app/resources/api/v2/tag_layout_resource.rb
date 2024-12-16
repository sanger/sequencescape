# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/tag_layouts/` endpoint.
    #
    # Provides a JSON:API representation of {TagLayout}.
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
      #   @return [String]
      #   @note This attribute is required.
      attribute :direction

      # @!attribute [rw] initial_tag
      #   An offset for the tag set indicating which tag to start with in the layout.
      #   @return [Integer]
      attribute :initial_tag

      # @!attribute [w] plate_uuid
      #   This is declared for convenience where the {Plate} is not available to set as a relationship.
      #   Setting this attribute alongside the `plate` relationship will prefer the relationship value.
      #   @deprecated Use the `plate` relationship instead.
      #   @param value [String] The UUID of the {Plate} this tag layout applies to.
      #   @return [Void]
      #   @see #plate
      attribute :plate_uuid, writeonly: true

      def plate_uuid=(value)
        @model.plate = Plate.with_uuid(value).first
      end

      # @!attribute [rw] substitutions
      #   A hash of substitutions to be applied to the tag layout.
      #   @return [Hash]
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
      #   This is declared for convenience where the {TagGroup} is not available to set as a relationship.
      #   Setting this attribute alongside the `tag_group` relationship will prefer the relationship value.
      #   @deprecated Use the `tag_group` relationship instead.
      #   @param value [String] The UUID of the {TagGroup} used in this tag layout.
      #   @return [Void]
      #   @see #tag_group
      attribute :tag_group_uuid, writeonly: true

      def tag_group_uuid=(value)
        @model.tag_group = TagGroup.with_uuid(value).first
      end

      # @!attribute [w] tag2_group_uuid
      #   This is declared for convenience where the second {TagGroup} is not available to set as a relationship.
      #   Setting this attribute alongside the `tag2_group` relationship will prefer the relationship value.
      #   @deprecated Use the `tag2_group` relationship instead.
      #   @param value [String] The UUID of the second {TagGroup} used in this tag layout.
      #   @return [Void]
      #   @see #tag2_group
      attribute :tag2_group_uuid, writeonly: true

      def tag2_group_uuid=(value)
        @model.tag2_group = TagGroup.with_uuid(value).first
      end

      # @!attribute [rw] tags_per_well
      #   The number of tags in each well.
      #   This is only used and/or returned by specific tag layout {walking_by} algorithms.
      #   At other times, this value will be `nil`.
      #   @return [Integer]
      attribute :tags_per_well

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the {User} is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the {User} who initiated this state change.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      # @!attribute [rw] walking_by
      #   The name of the algorithm defining the way of walking through the tag layout.
      #   @return [String]
      #   @note This attribute is required.
      attribute :walking_by

      ###
      # Relationships
      ###

      # @!attribute [rw] plate
      #   Setting this relationship alongside the `plate_uuid` attribute will override the attribute value.
      #   @return [Api::V2::PlateResource] The plate this tag layout applies to.
      #   @note This relationship is required.
      has_one :plate

      # @!attribute [rw] tag_group
      #   Setting this relationship alongside the `tag_group_uuid` attribute will override the attribute value.
      #   A relationship for the primary tag group associated with the tag layout template.
      #   @return [Api::V2::TagGroupResource]
      #   @note This relationship is required.
      has_one :tag_group

      # @!attribute [rw] tag2_group
      #   Setting this relationship alongside the `tag2_group_uuid` attribute will override the attribute value.
      #   A relationship for the secondary tag group associated with the tag layout template.
      #   This is used during dual indexing, but will not be found during single indexing.
      #   @return [Api::V2::TagGroupResource]
      has_one :tag2_group, class_name: 'TagGroup'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [Api::V2::UserResource] The user who initiated this state change.
      #   @note This relationship is required.
      has_one :user

      ###
      # Template attributes
      ###

      # These are consumed by the TagLayoutProcessor and not a concern of the resource.
      # They are included here to allow their presence in the JSON:API request body and to document their use cases.

      # @!attribute [w] tag_layout_template_uuid
      #   @param value [String] the UUID of a TagLayoutTemplate to use for attributes of this TagLayout resource.
      #     Providing this UUID while also providing values for attributes and relationships which can be extracted from
      #     a {TagLayoutTemplateResource} will generate an error indicating that the UUID should not have been provided.
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
