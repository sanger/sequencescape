#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013 Genome Research Ltd.
class Api::LibraryTubeIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::LibraryTubeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([
            :uuid_object,
            :barcode_prefix, {
              :source_request => [:uuid_object, :request_metadata],
              :primary_aliquot => { :sample => :uuid_object, :tag => [ :uuid_object, { :tag_group => :uuid_object } ] }
            },
            :scanned_into_lab_event
          ])}

        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      "library_tube"
    end
  end

  renders_model(::LibraryTube)

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
  map_attribute_to_json_attribute(:public_name)

  with_association(:scanned_into_lab_event) do
    map_attribute_to_json_attribute(:content, 'scanned_in_date')
  end

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  with_association(:primary_aliquot_if_unique) do
    with_association(:sample) do
      map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      map_attribute_to_json_attribute(:id,   'sample_internal_id')
      map_attribute_to_json_attribute(:name, 'sample_name')
    end

    with_association(:tag) do
      map_attribute_to_json_attribute(:uuid  , 'tag_uuid')
      map_attribute_to_json_attribute(:id    , 'tag_internal_id')
      map_attribute_to_json_attribute(:oligo , 'expected_sequence')
      map_attribute_to_json_attribute(:map_id, 'tag_map_id')

      with_association(:tag_group) do
        map_attribute_to_json_attribute(:name, 'tag_group_name')
        map_attribute_to_json_attribute(:uuid, 'tag_group_uuid')
        map_attribute_to_json_attribute(:id  , 'tag_group_internal_id')
      end
    end
  end

  with_association(:source_request) do
    map_attribute_to_json_attribute(:id,   'source_request_internal_id')
    map_attribute_to_json_attribute(:uuid, 'source_request_uuid')

    extra_json_attributes do |object, json_attributes|
      json_attributes["read_length"]                 = object.request_metadata.read_length  if object.is_a?(SequencingRequest)
      json_attributes["library_type"]                = object.request_metadata.library_type if object.is_a?(LibraryCreationRequest)
      json_attributes["fragment_size_required_from"] = object.request_metadata.fragment_size_required_from   if object.respond_to?(:fragment_size_required_from)
      json_attributes["fragment_size_required_to"]   = object.request_metadata.fragment_size_required_to     if object.respond_to?(:fragment_size_required_to)
    end
  end

  self.related_resources = [ :lanes, :requests ]
end
