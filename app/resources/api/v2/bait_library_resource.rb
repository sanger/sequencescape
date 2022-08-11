# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of BaitLibrary
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaitLibraryResource < BaseResource
      # Constants...

      immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations:
      # has_one :supplier

      # Attributes
      attribute :name, readonly: true

      # Filters
      filter :name

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
