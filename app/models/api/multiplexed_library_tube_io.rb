# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.
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

        scope :including_associations_for_json, -> { includes([:uuid_object, :barcode_prefix, :scanned_into_lab_event]) }
        alias_method(:json_root, :url_name)
      end
    end

    def related_resources
      ['parents', 'children', 'requests']
    end

    def url_name
      'multiplexed_library_tube'
    end
  end

  renders_model(::MultiplexedLibraryTube)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
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

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  with_association(:scanned_into_lab_event) do
    map_attribute_to_json_attribute(:content, 'scanned_in_date')
  end

  self.related_resources = [:lanes, :requests]
end
