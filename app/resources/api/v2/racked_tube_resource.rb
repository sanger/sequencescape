# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/racked_tubes/` endpoint.
    #
    # Provides a JSON:API representation of {RackedTube}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class RackedTubeResource < BaseResource
      # Constants...

      # model_name / model_hint if required

      # Associations:
      has_one :tube
      has_one :tube_rack

      # Attributes
      attribute :coordinate, write_once: true

      # Filters

      # Class method overrides

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
    end
  end
end
