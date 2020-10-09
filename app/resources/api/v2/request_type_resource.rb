# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of request_type
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class RequestTypeResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, readonly: true
      attribute :key, readonly: true
      attribute :for_multiplexing, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
