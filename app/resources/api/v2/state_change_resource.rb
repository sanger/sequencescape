# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {StateChange}
    #
    # A {StateChange} records a transition from one state to another for a piece of labware.
    #
    # @note Access this resource via the `/api/v2/state_changes/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example POST request to change the state of a target labware
    #   POST /api/v2/state_changes/
    #   {
    #     "data": {
    #         "type": "state_changes",
    #         "attributes": {
    #             "target_state": "passed",
    #             "user_uuid": "daa2b6be-3794-11ef-a6f5-26ddcd6c52d7",
    #             "customer_accepts_responsibility": false
    #         },
    #         "relationships": {
    #             "target": { "data": { "type": "labware", "id": 6 } },
    #             "user": { "data": { "type": "users", "id": 4 } }
    #         }
    #     }
    # }
    #
    # @example GET request for all StateChange records
    #   GET /api/v2/state_changes/
    #
    # @example GET request for a specific StateChange with ID 789
    #   GET /api/v2/state_changes/789/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class StateChangeResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] contents
      #   Some targets can have "contents" updated (notably plates).  The meaning of this is is dealt with by the
      #   target being updated.
      #   @note This is an optional attribute.
      #   @return [Array] Array of "contents" to fail, deciphered by the target.
      attribute :contents

      # @!attribute [w] customer_accepts_responsibility
      #   @param value [Boolean] Sets whether the customer proceeded against advice and will still be charged in the
      #     event of a failure.
      #   @return [Void]
      attribute :customer_accepts_responsibility, writeonly: true

      # @!attribute [r] previous_state
      #   The state of the target labware before this state change was applied.
      #   @return [String] The previous state of the target before this state change.
      attribute :previous_state, readonly: true

      # @!attribute [rw] reason
      #   The reason provided for the state change.
      #   This can be used to explain why the transition occurred.
      #   @return [String] The previous state of the target before this state change.
      attribute :reason

      # @!attribute [rw] target_state
      #   The new state to which the target will be transitioned.
      #   @return [String] The state of the target after this state change.
      #   @note This attribute is required.
      attribute :target_state

      # @!attribute [w] target_uuid
      #   This is provided as a shortcut for setting the `target` relationship.
      #   If both this attribute and the `target` relationship are provided, the relationship takes precedence.
      #   @deprecated Use the `target` relationship instead.
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      #   @param value [String] The UUID of the labware affected by this state change.
      #   @return [Void]
      #   @see #target
      attribute :target_uuid, writeonly: true

      def target_uuid=(value)
        @model.target = Labware.with_uuid(value).first
      end

      # @!attribute [w] user_uuid
      #   This is provided as a shortcut for setting the `user` relationship.
      #   If both this attribute and the `user` relationship are provided, the relationship takes precedence.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who performed this state change.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   The UUID identifier for this state change.
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @note This relationship is required.
      #   @return [UserResource] The user who initiated this state change.
      has_one :user

      # @!attribute [rw] target
      #   Setting this relationship alongside the `target_uuid` attribute will override the attribute value.
      #   @note This relationship is required.
      #   @return [LabwareResource] The target labware this state change applies to.
      has_one :target, class_name: 'Labware'
    end
  end
end
