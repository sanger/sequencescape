# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Well}
# Historically used to be v0.5 API
class Api::WellIO < Api::Base
  module Extensions # rubocop:todo Style/Documentation
    module ClassMethods # rubocop:todo Style/Documentation
      def render_class
        Api::WellIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json,
              lambda {
                includes([:uuid_object, :map, :well_attribute, :plate, { primary_aliquot: { sample: :uuid_object } }])
              }
      end
    end
  end
  renders_model(::Well)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:display_name)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:well_attribute) do
    map_attribute_to_json_attribute(:gel_pass, 'gel_pass')
    map_attribute_to_json_attribute(:concentration, 'concentration')
    map_attribute_to_json_attribute(:current_volume, 'current_volume')
    map_attribute_to_json_attribute(:buffer_volume, 'buffer_volume')
    map_attribute_to_json_attribute(:requested_volume, 'requested_volume')
    map_attribute_to_json_attribute(:picked_volume, 'picked_volume')
    map_attribute_to_json_attribute(:pico_pass, 'pico_pass')
    map_attribute_to_json_attribute(:measured_volume, 'measured_volume')
    map_attribute_to_json_attribute(:sequenom_count, 'sequenom_count')
    map_attribute_to_json_attribute(:gender_markers_string, 'gender_markers')
  end

  with_association(:map) { map_attribute_to_json_attribute(:description, 'map') }

  with_association(:plate) do
    map_attribute_to_json_attribute(:uuid, 'plate_uuid')
    with_association(:sanger_barcode) do
      map_attribute_to_json_attribute(:number_as_string, 'plate_barcode')
      map_attribute_to_json_attribute(:barcode_prefix, 'plate_barcode_prefix')
    end
  end

  with_association(:primary_aliquot_if_unique) do
    with_association(:sample) do
      map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      map_attribute_to_json_attribute(:id, 'sample_internal_id')
      map_attribute_to_json_attribute(:name, 'sample_name')
    end
  end
end
