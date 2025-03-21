# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PlateConversion} for converting a plate to a new purpose.
    # The converted target becomes linked as a child of the specified parent.
    # Creation of this resource via a `POST` request will initiate the conversion.
    # The converted plate is returned by this endpoint under the {#target} relationship.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/plate_conversions/` endpoint.
    #
    # @example POST request with arguments specified by UUID (deprecated)
    #   POST /api/v2/plate_conversions/
    #   {
    #     "data": {
    #       "type": "plate_conversions",
    #       "attributes": {
    #         "parent_uuid": "11111111-2222-3333-4444-555555666666",
    #         "purpose_uuid": "22222222-3333-4444-5555-666666777777",
    #         "target_uuid": "33333333-4444-5555-6666-777777888888",
    #         "user_uuid": "44444444-5555-6666-7777-888888999999"
    #       }
    #     }
    #   }
    #
    # @example POST request with arguments specified by relationship
    #   POST /api/v2/plate_conversions/
    #   {
    #     "data": {
    #       "type": "plate_conversions",
    #       "attributes": {},
    #       "relationships": {
    #         "parent": {
    #           "data": { "type": "plates", "id": "123" }
    #         },
    #         "purpose": {
    #           "data": { "type": "plate_purposes", "id": 1 }
    #         },
    #         "target": {
    #           "data": { "type": "plates", "id": 1 }
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": 4 }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all PlateConversion resources
    #   GET /api/v2/plate_conversions/
    #
    # @example GET request for a PlateConversion with ID 123
    #   GET /api/v2/plate_conversions/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PlateConversionResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] parent_uuid
      #   This is declared for convenience where the parent {Plate} is not available to set as a relationship.
      #   Setting this attribute alongside the `parent` relationship will prefer the relationship value.
      #   @deprecated Use the `parent` relationship instead.
      #   @param value [String] The UUID of the {Plate} to be linked as the parent of the `target` plate.
      #   @return [Void]
      #   @see #parent
      attribute :parent_uuid, writeonly: true

      def parent_uuid=(value)
        @model.parent = Plate.with_uuid(value).first
      end

      # @!attribute [w] purpose_uuid
      #   This is declared for convenience where the {PlatePurpose} is not available to set as a relationship.
      #   Setting this attribute alongside the `purpose` relationship will prefer the relationship value.
      #   @deprecated Use the `purpose` relationship instead.
      #   @param value [String] The UUID of the {PlatePurpose} to convert the `target` plate to.
      #   @return [Void]
      #   @see #purpose
      attribute :purpose_uuid, writeonly: true

      def purpose_uuid=(value)
        @model.purpose = PlatePurpose.with_uuid(value).first
      end

      # @!attribute [w] target_uuid
      #   This is declared for convenience where the target {Plate} is not available to set as a relationship.
      #   Setting this attribute alongside the `target` relationship will prefer the relationship value.
      #   @deprecated Use the `target` relationship instead.
      #   @param value [String] The UUID of the {Plate} to be converted to the specified `purpose` and linked as a
      #     child of the `parent` plate, if specified.
      #   @return [Void]
      #   @see #target
      attribute :target_uuid, writeonly: true

      def target_uuid=(value)
        @model.target = Plate.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the {User} is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the {User} who initiated this plate conversion.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the plate conversion.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] parent
      #   Setting this relationship alongside the `parent_uuid` attribute will override the attribute value.
      #   @return [Api::V2::PlateResource] The optional plate to become the parent of the converted target plate.
      has_one :parent, class_name: 'Plate'

      # @!attribute [rw] purpose
      #   Setting this relationship alongside the `purpose_uuid` attribute will override the attribute value.
      #   The purpose which the target plate should be converted to.
      #   @return [Api::V2::PlatePurposeResource]
      #   @note This relationship is required.
      has_one :purpose, class_name: 'PlatePurpose'

      # @!attribute [rw] target
      #   Setting this relationship alongside the `target_uuid` attribute will override the attribute value.
      #   The target of the plate conversion.
      #   This plate will be converted to the given purpose and made a child of the parent plate, if given.
      #   @return [Api::V2::PlateResource]
      #   @note This relationship is required.
      has_one :target, class_name: 'Plate'

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [Api::V2::UserResource] The user who initiated this plate conversion.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
