# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a RackedTube
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class RackedTubeResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations:
      has_one :tube
      has_one :tube_rack

      # Attributes
      attribute :coordinate, readonly: true

      # Filters

      # Class method overrides

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
    end
  end
end
