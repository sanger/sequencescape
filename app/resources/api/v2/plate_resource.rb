# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PlateResource < BaseResource
      # Constants...

      immutable # uncomment to make the resource immutable

      default_includes :uuid_object, :barcode_prefix

      # Associations:
      has_many :samples, readonly: true
      has_many :studies, readonly: true
      has_many :projects, readonly: true
      has_many :wells, readonly: true

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :labware_barcode, readonly: true

      # Filters
      filter :barcode, apply: (lambda do |records, value, _options|
        records.with_machine_barcode(value)
      end)

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.ean13_barcode,
          'sanger_human_barcode' => _model.sanger_human_barcode
        }
      end

      # Class method overrides
    end
  end
end
