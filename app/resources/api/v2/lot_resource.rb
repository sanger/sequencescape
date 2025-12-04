# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Lot}.
    #
    # A `Lot` represents a received batch of consumables (eg. tag plates)
    # that can be assumed to share some level of QC.
    # A lot can be generated from Gatekeeper.
    #
    # @note Access this resource via the `/api/v2/lots/` endpoint.
    # @note This resource supports retrieval and creation of lots but does not allow modification after creation.
    #
    # @example GET request to fetch all lots
    #   GET /api/v2/lots/
    #
    # @example GET request to fetch a specific lot by ID
    #   GET /api/v2/lots/123/
    #
    # @todo The below POST example is not currently supported by the API, but is included here for reference.
    #   This is because `received_at` is a required field in the model, but is not included in the resource.
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
    #
    # @example POST request to create a new lot
    #   POST /api/v2/lots/
    #   {
    #     "data": {
    #       "type": "lots",
    #       "attributes": {
    #         "lot_number": "ABC123"
    #         // "received_at": "11"
    #       },
    #       "relationships": {
    #         "lot_type": {
    #           "data": { "type": "lot_types", "id": "1" }
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": "1" }
    #         },
    #         "template": {
    #           "data": { "type": "tag_layout_templates", "id": "3" }
    #         }
    #         // "tag_layout_template": {
    #         //     "data": { "type": "tag_layout_templates", "id": "1"}
    #         // }
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class LotResource < BaseResource
      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [rw] template_type
      #   @note This field is required when creating a lot. It enables setting the polymorphic template relationship.
      #   @return [String] The template_type.
      attribute :template_type

      # @!attribute [rw] template_id
      #   @note This field is required when creating a lot. It enables setting the polymorphic template relationship.
      #   @return [String] The template_id.
      attribute :template_id

      # @!attribute [rw] received_at
      #  @note This field is required when creating a lot.
      #  @return [DateTime] The date and time when the lot was received.
      attribute :received_at, write_once: true

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The universally unique identifier (UUID) of the lot.
      attribute :uuid, readonly: true

      # @!attribute [rw] lot_number
      #   @note This field is required when creating a lot.
      #   @return [String] The lot number.
      attribute :lot_number, write_once: true

      # @!attribute [r] lot_type_name
      #   @return [String] The name of the lot type associated with this lot.
      attribute :lot_type_name, readonly: true

      # @!attribute [r] template_name
      #   @return [String] The name of the template associated with this lot.
      attribute :template_name, readonly: true

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the {User} is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      #   @param value [String] The UUID of the {User} who initiated this work completion.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [w] lot_type_uuid
      #  This is declared for convenience where the {LotType} is not available to set as a relationship.
      #  @param value [String] The UUID of the {LotType} related to this lot.
      attribute :lot_type_uuid, writeonly: true

      def lot_type_uuid=(value)
        @model.lot_type = LotType.with_uuid(value).first
      end

      ###
      # Getters and Setters
      ###

      # Retrieves the name of the lot type associated with this lot.
      #
      # @return [String, nil] The name of the lot type, or `nil` if no lot type is set.
      # e.g. 'Pre Stamped Tags'
      def lot_type_name
        lot_type&.name
      end

      # Retrieves the name of the template associated with this lot.
      # See template association below for more details.
      #
      # @return [String, nil] The name of the template, or `nil` if no template is set.
      # e.g. 'TSsc384-PCR2-nCoV-2019/V3/B'
      def template_name
        template&.name
      end

      ###
      # Custom Methods
      ###

      # Retrieves the template ID for the associated tag layout template.
      #
      # @return [String, nil] The template ID, or `nil` if no template is set.
      def tag_layout_template_id
        template_id
      end

      ###
      # Relationships
      ###

      # @!attribute [rw] lot_type
      #   The type of lot, which governs the behaviour of a {Lot}.
      #   @return [LotTypeResource] The associated lot type.
      #   @note This relationship is required when creating a lot.
      has_one :lot_type

      # @!attribute [rw] user
      #   The user who created or registered this lot.
      #   @return [UserResource] The associated user.
      #   @note This relationship is required when creating a lot.
      has_one :user

      # @!attribute [rw] template
      #   The template associated with this lot, which may vary depending on the lot type.
      #   This is a polymorphic relationship, meaning it can be linked to different entity types
      #   (TagLayoutTemplate, Tag2LayoutTemplate and Labware/PlateTemplate at time of writing).
      #   @return [TemplateResource] The associated template.
      #   @note This relationship is required when creating a lot.
      has_one :template, polymorphic: true

      # @!attribute [r] tag_layout_template
      #   A tag layout template associated with this lot, used for specific processing workflows.
      #   This represents the same entity as `template` above,
      #   but is only relevant when template_type is `TagLayoutTemplate`.
      #   @return [TagLayoutTemplateResource] The associated tag layout template.
      #   @note This relationship is loaded only when explicitly included.
      has_one :tag_layout_template, eager_load_on_include: false

      # @!attribute [rw] qcables
      #   @return [Array<QcableResource>] the {Qcable} resources related to this lot.
      has_many :qcables

      ###
      # Filters
      ###

      # @!method uuid
      #   A filter to return only lots with the given UUID.
      #   @example Filtering lots by UUID
      #     GET /api/v2/lots?filter[uuid]=11111111-2222-3333-4444-555555666666
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(*value) }

      filter :lot_number
    end
  end
end
