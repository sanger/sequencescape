# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    #
    # Provides a JSON:API representation of {Submission} which represents a collection of {Order}s submitted by a
    # {User}. The initial state of a {Submission} is `building`, during which time, {Order}s are added to it.
    # If the `and_submit` attribute is set to `true`, the new submission will be transitioned to the `pending` state
    # after validation is applied.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/submissions/` endpoint.
    #
    # @example POST request
    #   POST /api/v2/submissions/
    #   {
    #     "data": {
    #       "type": "submissions",
    #       "relationships": {
    #         "orders": {
    #           "data": [
    #             {
    #               "type": "orders",
    #               "id": "123"
    #             },
    #             {
    #               "type": "orders",
    #               "id": "456"
    #             }
    #           ]
    #         },
    #         "user": {
    #           "data": {
    #             "type": "users",
    #             "id": "123"
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all Submission resources
    #   GET /api/v2/submissions/
    #
    # @example GET request for a Submission with ID 123
    #   GET /api/v2/submissions/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SubmissionResource < BaseResource
      default_includes :uuid_object, :sequencing_requests

      ###
      # Attributes
      ###

      # Added for use in Limber Presenters to decide whether to show the pooling tab
      delegate :multiplexed?, to: :_model

      # CAUTION:
      # See app/controllers/api/v2/submissions_controller.rb
      # for field filtering, otherwise newly added attributes
      # will not show by default.

      # @!attribute [r] created_at
      #   @return [DateTime] the date and time the {Submission} was created as an ISO8601 string.
      attribute :created_at, readonly: true

      # @!attribute [r] updated_at
      #   @return [DateTime] the date and time the {Submission} was last updated as an ISO8601 string.
      attribute :updated_at, readonly: true

      # @!attribute [rw] lanes_of_sequencing
      #   @return [Integer] the number of lanes of sequencing requested in the Submission.
      #      This can only be written once on creation.
      attribute :lanes_of_sequencing, write_once: true
      attribute :multiplexed?, readonly: true

      def lanes_of_sequencing
        _model.sequencing_requests.size
      end

      # @!attribute [rw] name
      #   @return [String] the name of the {Submission}.
      #      This can only be written once on creation.
      attribute :name, write_once: true

      # @!attribute [w] order_uuids
      #   This is declared for convenience where the {Order} resources are not available to set as a relationship.
      #   Setting this attribute alongside the `orders` relationship will prefer the relationship value.
      #   @deprecated Use the `orders` relationship instead.
      #   @param value [Array<String>] the UUID of the {Order} resources associated with this {Submission}.
      #   @return [Void]
      #   @see #orders
      attribute :order_uuids, writeonly: true

      def order_uuids=(value)
        @model.orders = value.map { |uuid| Order.with_uuid(uuid).first }
      end

      # @!attribute [r] state
      #   @return [String] a string version of the state name for this {Submission}.
      #     This is one of `building`, `pending`, `processing`, `ready`, `failed` or `cancelled`.
      attribute :state, readonly: true

      # @!attribute [rw] used_tags
      #   @return [String] the tags that were used in this {Submission}.
      #      This can only be written once on creation.
      attribute :used_tags, write_once: true

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the {User} is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [Array<String>] the UUID of the {User} who created the {Submission}.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] the UUID of the {Submission}.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   The {User} who created the {Submission}.
      #   @return [Api::V2::UserResource]
      #   @note This relationship is required.
      has_one :user, class_name: 'User'

      # @!attribute [rw] orders
      #   Setting this relationship alongside the `orders_uuids` attribute will override the attribute value.
      #   The {Order} resources which are associated with the {Submission}.
      #   @return [Array<Api::V2::OrderResource>]
      has_many :orders, class_name: 'Order'

      ###
      # Filters
      ###

      # @!method filter_uuid
      #   Filter the {Submission} resources by UUID.
      #   @example GET request with UUID filter
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

      attribute :and_submit, writeonly: true
      attr_writer :and_submit # Stored so that the after_replace_fields callback knows whether to submit the submission.
    end
  end
end
