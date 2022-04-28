# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of submission
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class SubmissionResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # model_name / model_hint if required

      default_includes :uuid_object, :sequencing_requests

      # Associations:

      # Attributes
      # CAUTION:
      # See app/controllers/api/v2/submissions_controller.rb
      # for field filtering, otherwise newly added attributes
      # will not show by default.
      attribute :uuid, readonly: true
      attribute :name, readonly: true
      attribute :state, readonly: true
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true
      attribute :used_tags, readonly: true
      attribute :lanes_of_sequencing, readonly: true

      # Filters
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      def lanes_of_sequencing
        _model.sequencing_requests.size
      end

      # Class method overrides
    end
  end
end
