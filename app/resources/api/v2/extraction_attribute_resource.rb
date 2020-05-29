# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of ExtractionAttribute
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class ExtractionAttributeResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations:

      # Attributes
      attribute :attributes_update
      attribute :created_by
      attribute :target_id

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
    end
  end
end
