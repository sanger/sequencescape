#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013 Genome Research Ltd.
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

        scope :including_associations_for_json, -> { includes([:uuid_object, :plate_metadata, :barcode_prefix, :location, { :plate_purpose => :uuid_object } ]) }
        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      "plate"
    end
  end
  renders_model(::Plate)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
  map_attribute_to_json_attribute(:size)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:plate_metadata) do
    map_attribute_to_json_attribute(:infinium_barcode)
    map_attribute_to_json_attribute(:fluidigm_barcode)
  end

  with_association(:location) do
    map_attribute_to_json_attribute(:name, 'location')
  end

  with_association(:plate_purpose, :if_nil_use => :stock_plate_purpose) do
    map_attribute_to_json_attribute(:name, 'plate_purpose_name')
    map_attribute_to_json_attribute(:id,   'plate_purpose_internal_id')
    map_attribute_to_json_attribute(:uuid, 'plate_purpose_uuid')

    def self.stock_plate_purpose
      PlatePurpose.find_by_name('Stock Plate')
    end
  end

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end
end
