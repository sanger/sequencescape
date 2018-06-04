
class Api::PlateIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::PlateIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, :plate_metadata, :barcodes, { plate_purpose: :uuid_object }]) }
      end
    end

    def json_root
      'plate'
    end
  end
  renders_model(::Plate)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode_number, 'barcode')
  map_attribute_to_json_attribute(:size)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  map_attribute_to_json_attribute(:infinium_barcode)
  map_attribute_to_json_attribute(:fluidigm_barcode)

  with_association(:plate_purpose, if_nil_use: :stock_plate_purpose) do
    map_attribute_to_json_attribute(:name, 'plate_purpose_name')
    map_attribute_to_json_attribute(:id,   'plate_purpose_internal_id')
    map_attribute_to_json_attribute(:uuid, 'plate_purpose_uuid')

    def self.stock_plate_purpose
      PlatePurpose.find_by(name: 'Stock Plate')
    end
  end

  map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
end
