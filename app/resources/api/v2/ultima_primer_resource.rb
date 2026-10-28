# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {UltimaPrimer}.
    #
    # An Ultima primer is a UGA or UGB primer (e.g. "UG-tR1", "UG-tR2") referenced by an
    # {UltimaApplication}. It is normally retrieved as an included relationship of an
    # Ultima application.
    #
    # @note Access this resource via the `/api/v2/ultima_primers/` endpoint.
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    #
    # @example GET request for all Ultima primers
    #   GET /api/v2/ultima_primers/
    #
    # @example GET request for a specific Ultima primer by ID
    #   GET /api/v2/ultima_primers/1
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class UltimaPrimerResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   The name of the primer, e.g. "UG-tR1".
      #   @return [String]
      attribute :name, readonly: true
    end
  end
end
