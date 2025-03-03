# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/labware/` endpoint.
    #
    # Provides a JSON:API representation of {Labware}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class LabwareResource < BaseResource
      # We import most labware shared behaviour, this includes associations,
      # attributes and filters. By adding behaviour here we ensure that it
      # is automatically available on plate and tube.
      include Api::V2::SharedBehaviour::Labware

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.try(:ean13_barcode),
          'machine_barcode' => _model.try(:machine_barcode),
          'human_barcode' => _model.try(:human_barcode)
        }
      end
    end
  end
end
