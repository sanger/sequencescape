# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class LaneResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # Associations:
      has_many :samples
      has_many :studies
      has_many :projects

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name
      # attribute :position
      # attribute :labware_barcode

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      # def labware_barcode
      #   {
      #     ean13_barcode: _model.labware.ean13_barcode,
      #     human_barcode: _model.labware.human_barcode
      #   }
      # end

      # Class method overrides
    end
  end
end
