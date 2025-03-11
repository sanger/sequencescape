# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Order}, which is the primary means of requesting work.
    # Orders are created via a `POST` request and must include a {#submission_template_uuid=} and a
    # {#submission_template_attributes=} hash.

    # An Order is used as the main means of requesting work in Sequencescape. Its
    # key components are:
    # Study: The study for which work is being undertaken
    # Project: The project who will be charged for the work
    # Request options: The parameters for the request which will be built. eg. read length
    # Request Types: An array of request type ids which will be built by the order.
    #                This is populated based on the submission template used.
    # Submission: Multiple orders may be grouped together in a submission. This
    #             associates the two sets of requests, and is usually used to determine
    #             what gets pooled together during multiplexing. As a result, sequencing
    #             requests may be shared between multiple orders.

    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/orders/` endpoint.
    #
    # @example POST request to create an order
    #   POST /api/v2/orders/
    # {
    #   "data": {
    #     "type": "orders",
    #     "attributes": {
    #       "submission_template_uuid": "9daf8d28-7cdf-11ef-b4cc-000000000000",
    #       "submission_template_attributes": {
    #         "asset_uuids": [ "e9580eea-fe6b-11ef-ba74-000000000000"],
    #         "autodetect_projects": true,
    #         "autodetect_studies": false,
    #       "request_options": {
    #           "library_type": "Chromium single cell 3 prime v3",
    #           "fragment_size_required_from": "200",
    #           "fragment_size_required_to": "800"
    #       },
    #         "user_uuid": "d8c22e20-f45d-11ef-8842-000000000000"
    #       }
    #     }
    #   }
    # }
    #
    # @example GET request for all Order resources
    #   GET /api/v2/orders/
    #
    # @example GET request for a specific Order with ID 123
    #   GET /api/v2/orders/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class OrderResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] order_type
      #   @return [String] The Single Table Inheritance (STI) type of the {Order}.
      attribute :order_type, delegate: :sti_type, readonly: true

      # @!attribute [r] request_options
      #   @return [Hash] Request options for the {Order}.
      #   @note These can only be set upon creation.
      attribute :request_options, readonly: true

      # @!attribute [r] request_types
      #   @return [Array<Integer>] The IDs of request types associated with this {Order}.
      #   @note These can only be set upon creation.
      attribute :request_types, readonly: true

      # @!attribute [r] uuid
      #   @return [String] The UUID of this {Order}.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] project
      #   @return [ProjectResource] The project associated with this {Order}.
      #   @note This can only be set once upon creation.
      has_one :project, readonly: true

      # @!attribute [r] study
      #   @return [StudyResource] The study associated with this {Order}.
      #   @note This can only be set once upon creation.
      has_one :study, readonly: true

      # @!attribute [r] user
      #   @return [UserResource] The user who created this {Order}.
      #   @note This can only be set once upon creation.
      has_one :user, readonly: true

      ###
      # Templated Creation
      ###

      # @!attribute [w] submission_template_uuid
      #   @return [String] The UUID of the {SubmissionTemplate} to use when creating this {Order}.
      #   @note This is mandatory for creating new {Order}s via the API and is not stored.
      attribute :submission_template_uuid, writeonly: true
      attr_writer :submission_template_uuid # Not stored, consumed by OrderProcessor.

      # @!attribute [w] submission_template_attributes
      #   @return [Hash] A hash of additional attributes used when creating this {Order} from a
      #     given {SubmissionTemplate}.
      #
      #   The structure is as follows:
      #
      #   ```json
      #   {
      #     "asset_uuids": ["String"],
      #     "autodetect_projects": "Boolean",  // optional
      #     "autodetect_studies": "Boolean",   // optional
      #     "request_options": "Hash",
      #     "user_uuid": "String"
      #   }
      #   ```
      #
      #   @note This is mandatory for creating new {Order}s via the API and is not stored.
      attribute :submission_template_attributes, writeonly: true
      attr_writer :submission_template_attributes # Not stored, consumed by OrderProcessor.

      # Handles the creation of an {Order} using the specified template.
      #
      # @param context [Hash] The context containing template information.
      # @return [OrderResource] The newly created {OrderResource}.
      def self.create(context)
        return super if context[:template].nil?

        order = context[:template].create_order!(context[:template_attributes])
        new(order, context)
      end
    end
  end
end
