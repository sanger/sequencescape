# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {MultiplexedLibraryTube}
# Historically used to be v0.5 API
class Api::MultiplexedLibraryTubeIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::MultiplexedLibraryTubeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes(%i[uuid_object barcodes scanned_into_lab_event]) }
      end
    end

    def json_root
      'multiplexed_library_tube'
    end
  end

  renders_model(::MultiplexedLibraryTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode_number, 'barcode')
  map_attribute_to_json_attribute(:concentration)
  map_attribute_to_json_attribute(:volume)
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:closed)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:public_name)

  map_attribute_to_json_attribute(:prefix, 'barcode_prefix')

  with_association(:scanned_into_lab_event) { map_attribute_to_json_attribute(:content, 'scanned_in_date') }
end
