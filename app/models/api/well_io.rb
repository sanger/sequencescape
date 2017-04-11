# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Api::WellIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::WellIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, :map, :well_attribute, :plate, { primary_aliquot: { sample: :uuid_object } }]) }
      end
    end
  end
  renders_model(::Well)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:display_name)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  extra_json_attributes do |object, json_attributes|
    sample = object.primary_aliquot_if_unique.try(:sample)
    if sample.present?
      json_attributes['genotyping_status']       = object.genotyping_status
      json_attributes['genotyping_snp_plate_id'] = sample.genotyping_snp_plate_id
    end
  end

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

  with_association(:map) do
    map_attribute_to_json_attribute(:description, 'map')
  end

  with_association(:plate) do
    map_attribute_to_json_attribute(:barcode, 'plate_barcode')
    map_attribute_to_json_attribute(:uuid, 'plate_uuid')

    extra_json_attributes do |object, json_attributes|
      json_attributes['plate_barcode_prefix'] = object.prefix unless object.nil?
    end
  end

  with_association(:primary_aliquot_if_unique) do
    with_association(:sample) do
      map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      map_attribute_to_json_attribute(:id, 'sample_internal_id')
      map_attribute_to_json_attribute(:name, 'sample_name')
    end
  end

  self.related_resources = [:lanes, :requests]
end
