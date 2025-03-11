# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Submission}.

    # A {Submission} collects multiple {Orders} together, to define a body of work.
    # In the case of non-multiplexed requests the submission is largely redundant,
    # but for multiplexed requests it usually helps define which assets will get
    # pooled together at multiplexing.

    #
    # @note Access this resource via the `/api/v2/submissions/` endpoint.
    # @note This resource cannot be modified after creation; its endpoint does not accept `PATCH` requests.
    #
    # @example GET request for all Submission resources
    #   GET /api/v2/submissions/
    #
    # @example GET request for a specific Submission by ID
    #   GET /api/v2/submissions/123/
    #
    # @example POST request with orders and user
    # POST /api/v2/submissions/
    #   {
    #     "data": {
    #         "type": "submissions",
    #         "attributes": {
    #             "name": "name",
    #             "and_submit": true
    #         },
    #         "relationships": {
    #             "orders": {
    #               "data": [
    #                 { "type": "orders", "id": "1" },
    #                 { "type": "orders", "id": "2" }
    #               ]
    #             },
    #             "user": {
    #               "data": { "type": "users", "id": "1" }
    #             }
    #           }
    #     }
    # }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class SubmissionResource < BaseResource
      ###
      # Attributes
      ###
      attr_writer :and_submit # Stored so that the after_replace_fields callback knows whether to submit the submission.

      # CAUTION:
      # See app/controllers/api/v2/submissions_controller.rb
      # for field filtering, otherwise newly added attributes
      # will not show by default.

      # @!attribute [r] created_at
      #   @return [DateTime] The date and time the {Submission} was created, formatted as an ISO8601 string.
      attribute :created_at, readonly: true

      # @!attribute [r] updated_at
      #   @return [DateTime] The date and time the {Submission} was last updated, formatted as an ISO8601 string.
      attribute :updated_at, readonly: true

      # @!attribute [rw] lanes_of_sequencing
      #   The number of lanes of sequencing requested in the {Submission}.
      #   @return [Integer]
      #   @note This value can only be set once at creation.
      attribute :lanes_of_sequencing, write_once: true

      def lanes_of_sequencing
        _model.sequencing_requests.size
      end

      # @!attribute [w] and_submit
      #   When set to `true`, the {Submission} transitions from `building` to `pending` after creation.
      #   @return [Boolean]
      attribute :and_submit, writeonly: true

      # @!attribute [rw] name
      #   The name of the {Submission}.
      #   @return [String]
      #   @note This value can only be set once at creation.
      attribute :name, write_once: true

      # @!attribute [w] order_uuids
      #   Convenience attribute to associate orders via UUIDs instead of relationships.
      #   @deprecated Use the `orders` relationship instead.
      #   If both `order_uuids` and `orders` are set, the `orders` relationship takes precedence.
      #   @param value [Array<String>] Array of UUIDs of {Order} resources associated with this {Submission}.
      #   @return [Void]
      #   @see #orders
      attribute :order_uuids, writeonly: true

      def order_uuids=(value)
        @model.orders = value.map { |uuid| Order.with_uuid(uuid).first }
      end

      # @!attribute [r] state
      #   The current state of the {Submission}.
      #   Possible values: `building`, `pending`, `processing`, `ready`, `failed`, or `cancelled`.
      #   @return [String]
      attribute :state, readonly: true

      # @!attribute [rw] used_tags
      #   Tags used in this {Submission}.
      #   @return [String]
      #   @note This value can only be set once at creation.
      attribute :used_tags, write_once: true

      # @!attribute [w] user_uuid
      #   Convenience attribute to associate the submitting user via UUID instead of relationships.
      #   @deprecated Use the `user` relationship instead.
      #   If both `user_uuid` and `user` are set, the `user` relationship takes precedence.
      #   @param value [String] The UUID of the {User} who created the {Submission}.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   The unique identifier for the {Submission}.
      #   @note This value is read-only and is generated automatically.
      #   @return [String]
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] user
      #   The {User} who created the {Submission}.
      #   Setting this relationship alongside `user_uuid` will override the attribute value.
      #   @return [Api::V2::UserResource]
      #   @note This relationship is required.
      has_one :user, class_name: 'User'

      # @!attribute [rw] orders
      #   The collection of {Order} resources associated with the {Submission}.
      #   Setting this relationship alongside `order_uuids` will override the attribute value.
      #   @return [Array<Api::V2::OrderResource>]
      has_many :orders, class_name: 'Order'

      ###
      # Filters
      ###

      # @!method filter_uuid
      #   Filter {Submission} resources by UUID.
      #   @example GET request using UUID filter
      #     GET /api/v2/submissions?filter[uuid]=12345678-1234-1234-1234-123456789012
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      ###
      # Post-create state changer
      ###

      after_replace_fields :submit!

      def submit!
        return unless @and_submit

        @model.built!
      end
    end
  end
end
