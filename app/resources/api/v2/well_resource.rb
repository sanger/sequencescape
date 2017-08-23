# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class WellResource < BaseResource
      # Constants...

      immutable # uncomment to make the resource immutable

      default_includes :uuid, :map, plate: :barcode_prefix

      # Associations:
      has_many :samples, readonly: true
      has_many :studies, readonly: true
      has_many :projects, readonly: true

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :position, readonly: true
      attribute :labware_barcode, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.plate&.ean13_barcode,
          'sanger_human_barcode' => _model.plate&.sanger_human_barcode
        }
      end

      def position
        {
          'name' => _model.map_description
        }
      end

      # Class method overrides
    end
  end
end
