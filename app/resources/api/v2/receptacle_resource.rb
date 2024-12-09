# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/receptacles/` endpoint.
    #
    # Provides a JSON:API representation of {Receptacle}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class ReceptacleResource < BaseResource
      # We import most receptacle shared behaviour, this includes associations,
      # attributes and filters. By adding behaviour here we ensure that it
      # is automatically available on well.
      include Api::V2::SharedBehaviour::Receptacle

      default_includes :uuid_object
    end
  end
end
