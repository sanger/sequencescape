# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Order} which are used as the main means of requesting work.
    # Creation of this resource via a `POST` request which must include a {#submission_template_uuid=} and a
    # {#submission_template_attributes=} hash.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/tube_from_tube_creations/` endpoint.
    #
    # @example POST request with child purpose and parent tube specified by UUID (deprecated)
    #   POST /api/v2/tube_from_tube_creations/
    #   {
    #     "data": {
    #       "type": "tube_from_tube_creations",
    #       "attributes": {
    #         "child_purpose_uuid": "11111111-2222-3333-4444-555555666666",
    #         "parent_uuid": "33333333-4444-5555-6666-777777888888",
    #         "user_uuid": "99999999-0000-1111-2222-333333444444"
    #       }
    #     }
    #   }
    #
    # @example POST request with child purpose and parent tube specified by relationship
    #   POST /api/v2/tube_from_tube_creations/
    #   {
    #     "data": {
    #       "type": "tube_from_tube_creations",
    #       "attributes": {},
    #       "relationships": {
    #         "child_purpose": {
    #           "data": { "type": "tube_purposes", "id": "123" }
    #         },
    #         "parent": {
    #           "data": { "type": "tubes", "id": "456" }
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": "789" }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all TubeFromTubeCreation resources
    #   GET /api/v2/tube_from_tube_creations/
    #
    # @example GET request for a TubeFromTubeCreation with ID 123
    #   GET /api/v2/tube_from_tube_creations/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class OrderResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] order_type
      #   @return [String] the STI type of the {Order}.
      attribute :order_type, delegate: :sti_type, readonly: true

      # @!attribute [r] request_options
      #   @return [Hash] request options for the {Order}.
      #   @note These can only be set once upon creation of the {Order}.
      attribute :request_options, readonly: true

      # @!attribute [r] request_types
      #   @return [Array<Integer>] the IDs of types of request in this {Order}.
      #   @note These can only be set once upon creation of the {Order}.
      attribute :request_types, readonly: true

      # Attributes
      # @!attribute [r] uuid
      #   @return [String] the UUID for this {Order}.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] project
      #   @return [ProjectResource] the project associated with this Order.
      #   @note This can only be set once upon creation of the Order.
      has_one :project, readonly: true

      # @!attribute [r] study
      #   @return [StudyResource] the study associated with this Order.
      #   @note This can only be set once upon creation of the {Order}.
      has_one :study, readonly: true

      # @!attribute [r] user
      #   @return [UserResource] the user who created this {Order}.
      #   @note This can only be set once upon creation of the {Order}.
      has_one :user, readonly: true

      ###
      # Templated creation
      ###

      # These are defined here to assist with the creation of Orders from SubmissionTemplates.
      # The values given are not stored in the Order and will be consumed by the OrderProcessor.

      # @!attribute [w] submission_template_uuid
      #   The UUID of the {SubmissionTemplate} to use when creating this {Order}.
      #   @note This is mandatory when creating new {Order}s via the API. It is not stored.
      attribute :submission_template_uuid, writeonly: true
      attr_writer :submission_template_uuid # Do not store this on the model. It's consumed by the OrderProcessor.

      # @!attribute [w] submission_template_attributes
      #   A hash of additional attributes to use when creating this {Order} from a given {SubmissionTemplate}.
      #   The structure of this hash is as follows:
      #
      #   ```json
      #   {
      #     "asset_uuids": [String],
      #     "autodetect_projects": Boolean,  // optional
      #     "autodetect_studies": Boolean,   // optional
      #     "request_options": Hash,
      #     "user_uuid": String
      #   }
      #   ```
      #
      #   @note This is mandatory when creating new {Order}s via the API. It is not stored.
      attribute :submission_template_attributes, writeonly: true
      attr_writer :submission_template_attributes # Do not store this on the model. It's consumed by the OrderProcessor.

      def self.create(context)
        return super if context[:template].nil?

        order = context[:template].create_order!(context[:template_attributes])
        new(order, context)
      end
    end
  end
end
