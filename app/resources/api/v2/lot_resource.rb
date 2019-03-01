# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Lot
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class LotResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :lot_type
      has_one :user
      has_one :template, polymorphic: true

      # Attributes
      attribute :uuid, readonly: true
      attribute :lot_number, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
