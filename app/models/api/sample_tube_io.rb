# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {SampleTube}
# Historically used to be v0.5 API
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

        scope :including_associations_for_json,
              lambda {
                includes(
                  [:uuid_object, :barcodes, { primary_aliquot: { sample: :uuid_object } }, :scanned_into_lab_event]
                )
              }
      end
    end
  end
  renders_model(::SampleTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode_number, 'barcode')
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:closed)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:concentration)
  map_attribute_to_json_attribute(:volume)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:scanned_into_lab_event) { map_attribute_to_json_attribute(:content, 'scanned_in_date') }

  map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  with_association(:primary_aliquot_if_unique) do
    with_association(:sample) do
      map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      map_attribute_to_json_attribute(:id, 'sample_internal_id')
      map_attribute_to_json_attribute(:name, 'sample_name')
    end
  end
end
