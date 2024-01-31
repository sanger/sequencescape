# frozen_string_literal: true

module Api
  module V2
    # LabwareResource
    class LabwareResource < BaseResource
      # We import most labware shared behaviour, this includes associations,
      # attributes and filters. By adding behaviour here we ensure that it
      # is automatically available on plate and tube.
      include Api::V2::SharedBehaviour::Labware

      default_includes :uuid_object, :barcodes, :purpose

      # Custom methods
      # These shouldn't be used for business logic, and a more about
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
