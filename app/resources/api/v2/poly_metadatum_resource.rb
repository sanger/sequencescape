# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of PolyMetadatum
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PolyMetadatumResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations:
      belongs_to :metadatable, polymorphic: true

      # Attributes
      attribute :key
      attribute :value
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
