# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/state_changes/` endpoint.
    #
    # Provides a JSON:API representation of {StateChange}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class StateChangeResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] contents
      #   @return [Array] Array of "contents" to fail, deciphered by the target.
      attribute :contents

      # @!attribute [w] customer_accepts_responsibility
      #   @param value [Boolean] Sets whether the customer proceeded against advice and will still be charged in the the event of a failure.
      #   @return [Void]
      attribute :customer_accepts_responsibility

      # @!attribute [r] previous_state
      #   @return [String] The previous state of the target before this state change.
      attribute :previous_state, readonly: true

      # @!attribute [rw] reason
      #   @return [String] The previous state of the target before this state change.
      attribute :reason

      # @!attribute [rw] target_state
      #   @return [String] The state of the target after this state change.
      #   @note This attribute is required.
      attribute :target_state

      # @!attribute [w] target_uuid
      #   This is declared for convenience where the target is not available to set as a relationship.
      #   Setting this attribute alongside the `target` relationship will prefer the relationship value.
      #   @param uuid [String] The UUID of the target labware this state change applies to.
      #   @return [Void]
      #   @see #target
      attribute :target_uuid

      def target_uuid=(uuid)
        @model.target = Labware.with_uuid(uuid).first
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @param uuid [String] The UUID of the user who initiated this state change.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid

      def user_uuid=(uuid)
        @model.user = User.with_uuid(uuid).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated this state change.
      #   @note This relationship is required.
      has_one :user

      # @!attribute [rw] target
      #   Setting this relationship alongside the `target_uuid` attribute will override the attribute value.
      #   @return [LabwareResource] The target labware this state change applies to.
      #   @note This relationship is required.
      has_one :target, class_name: 'Labware'

      def self.creatable_fields(context)
        # Previous state and UUID are set by the system.
        super - %i[previous_state uuid]
      end

      def fetchable_fields
        # The customer_accepts_responsibility attribute is only available during resource creation.
        # UUIDs for relationships are not fetchable. They should be accessed via the relationship itself.
        super - %i[customer_accepts_responsibility target_uuid user_uuid]
      end
    end
  end
end
