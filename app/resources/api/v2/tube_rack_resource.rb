# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of TubeRack
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TubeRackResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object, :barcodes

      # Associations:
      has_many :racked_tubes
      has_many :comments, readonly: true
      has_one :purpose, foreign_key: :plate_purpose_id

      # Attributes
      attribute :uuid, readonly: true
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true
      attribute :labware_barcode, readonly: true
      attribute :size
      attribute :number_of_rows, readonly: true
      attribute :number_of_columns, readonly: true
      attribute :name, readonly: true

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   purpose = Purpose.find_by(name: value)
                   records.where(plate_purpose_id: purpose)
                 end
               )
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.ean13_barcode,
          'machine_barcode' => _model.machine_barcode,
          'human_barcode' => _model.human_barcode
        }
      end
    end
  end
end
