class Api::SampleTubeIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::SampleTubeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        named_scope :including_associations_for_json, { :include => [ :uuid_object, :barcode_prefix, { :primary_aliquot => { :sample => :uuid_object } }, :scanned_into_lab_event ] }
      end
    end
  end
  renders_model(::SampleTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:closed)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:concentration)
  map_attribute_to_json_attribute(:volume)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:scanned_into_lab_event) do
    map_attribute_to_json_attribute(:content, 'scanned_in_date')
  end

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  with_association(:primary_aliquot_if_unique) do
    with_association(:sample) do
      map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      map_attribute_to_json_attribute(:id  , 'sample_internal_id')
      map_attribute_to_json_attribute(:name, 'sample_name')
    end
  end

  self.related_resources = [ :library_tubes, :requests ]
end
