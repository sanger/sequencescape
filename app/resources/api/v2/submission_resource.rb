# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo Confirm the API examples work as expected.
    #
    # Provides a JSON:API representation of {Submission} which represents a collection of {Order}s submitted by a
    # {User}. Once submitted, the {Submission} is processed by a state machine.
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
    # @example GET request for all Submission resources associated with a User with ID 123
    #   GET /api/v2/users/123/submissions/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SubmissionResource < BaseResource
      default_includes :uuid_object, :sequencing_requests

      ###
      # Attributes
      ###

      # CAUTION:
      # See app/controllers/api/v2/submissions_controller.rb
      # for field filtering, otherwise newly added attributes
      # will not show by default.

      # @!attribute [r] created_at
      #   @return [DateTime] The date and time the Submission was created.
      attribute :created_at, readonly: true

      # @!attribute [rw] lanes_of_sequencing
      #   @todo: check types of this attribute
      #   @return [Integer] The number of lanes of sequencing requested in the Submission.
      #      This can only be written once on creation.
      attribute :lanes_of_sequencing, write_once: true

      def lanes_of_sequencing
        _model.sequencing_requests.size
      end

      attribute :name, write_once: true

      attribute :order_uuids, writeonly: true

      def order_uuids=(value)
        @model.orders = value.map { |uuid| Order.with_uuid(uuid).first }
      end

      attribute :state, readonly: true
      attribute :updated_at, readonly: true
      attribute :used_tags, write_once: true

      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      has_one :user, class_name: 'User'

      has_many :orders, class_name: 'Order'

      ###
      # Filters
      ###

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
