# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {PacBioLibraryTube}
# Historically used to be v0.5 API
class Api::PacBioLibraryTubeIO < Api::Base
  module Extensions # rubocop:todo Style/Documentation
    module ClassMethods # rubocop:todo Style/Documentation
      def render_class
        Api::PacBioLibraryTubeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes(%i[uuid_object barcodes scanned_into_lab_event]) }
      end
    end
  end

  renders_model(::PacBioLibraryTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
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

  with_association(:pac_bio_library_tube_metadata) do
    map_attribute_to_json_attribute(:prep_kit_barcode)
    map_attribute_to_json_attribute(:binding_kit_barcode)
    map_attribute_to_json_attribute(:smrt_cells_available)
    map_attribute_to_json_attribute(:movie_length)
    map_attribute_to_json_attribute(:protocol)
  end

  map_attribute_to_json_attribute(:prefix, 'barcode_prefix')

  with_association(:scanned_into_lab_event) { map_attribute_to_json_attribute(:content, 'scanned_in_date') }
end
