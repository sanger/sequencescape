# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of purpose
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PurposeResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, readonly: true
      attribute :size, readonly: true
      attribute :lifespan, readonly: true

      # Filters
      filter :name

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
