# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/tube_purposes/` endpoint.
    #
    # Provides a JSON:API representation of {Tube::Purpose}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubePurposeResource < BaseResource
      model_name 'Tube::Purpose'

      #####
      # Attributes
      #####

      # @!attribute [rw] name
      #   @return [String] the name of the tube purpose.
      attribute :name

      # @!attribute [rw] purpose_type
      #   @return [String] the purpose type. This is mapped to the type attribute on the model.
      attribute :purpose_type, delegate: :type

      # @!attribute [rw] target_type
      #   @return [String] the target type.
      attribute :target_type

      # @!attribute [r] uuid
      #   @return [String] the UUID of the tube purpose.
      attribute :uuid, readonly: true

      filter :type, default: 'Tube::Purpose'
    end
  end
end
