class Api::PacBioLibraryTubeIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::PacBioLibraryTubeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        named_scope :including_associations_for_json, { :include => [:uuid_object, :barcode_prefix ] }
      end
    end
  end

  renders_model(::PacBioLibraryTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
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

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  extra_json_attributes do |object, json_attributes|
    json_attributes["scanned_in_date"] = object.scanned_in_date if object.respond_to?(:scanned_in_date)
  end
end
