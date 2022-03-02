# frozen_string_literal: true

module Api
  module V2
    # LabwareResource
    class LabwareResource < BaseResource
      # We import most labware shared behaviour, this includes associations,
      # attributes and filters. By adding behaviour here we ensure that it
      # is automatically available on plate and tube.
      include Api::V2::SharedBehaviour::Labware

      default_includes :uuid_object, :barcodes
    end
  end
end
