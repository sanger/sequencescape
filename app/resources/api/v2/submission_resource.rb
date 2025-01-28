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
      # Constants...

      immutable

      # model_name / model_hint if required

      default_includes :uuid_object, :sequencing_requests

      # Associations:

      # Attributes
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
      attribute :is_multiplexed, readonly: true

      # Filters
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      def lanes_of_sequencing
        _model.sequencing_requests.size
      end

      # Added for use in Limber Presenters to decide whether to show the pooling tab
      def is_multiplexed
        _model.multiplexed?
      end

      # Class method overrides
    end
  end
end
