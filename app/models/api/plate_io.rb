# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Plate}
# Historically used to be v0.5 API
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

        scope :including_associations_for_json,
              lambda { includes([:uuid_object, :plate_metadata, :barcodes, { plate_purpose: :uuid_object }]) }
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
  with_association(:sanger_barcode) do
    map_attribute_to_json_attribute(:number_as_string, 'barcode')
    map_attribute_to_json_attribute(:barcode_prefix, 'barcode_prefix')
  end
  map_attribute_to_json_attribute(:size)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  map_attribute_to_json_attribute(:infinium_barcode)
  map_attribute_to_json_attribute(:fluidigm_barcode)

  with_association(:plate_purpose, if_nil_use: :stock_plate_purpose) do
    map_attribute_to_json_attribute(:name, 'plate_purpose_name')
    map_attribute_to_json_attribute(:id, 'plate_purpose_internal_id')
    map_attribute_to_json_attribute(:uuid, 'plate_purpose_uuid')

    def self.stock_plate_purpose
      PlatePurpose.stock_plate_purpose
    end
  end
end
