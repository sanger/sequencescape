# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/submissions/` endpoint.
    #
    # Provides a JSON:API representation of {Submission}.
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

      attribute :uuid, readonly: true
      attribute :name, write_once: true
      attribute :state, readonly: true
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true
      attribute :used_tags, write_once: true
      attribute :lanes_of_sequencing, write_once: true

      def lanes_of_sequencing
        _model.sequencing_requests.size
      end

      attribute :order_uuids, writeonly: true

      def order_uuids=(value)
        @model.orders = value.map { |uuid| Order.with_uuid(uuid).first }
      end

      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

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
