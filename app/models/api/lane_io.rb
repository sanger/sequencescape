#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class Api::LaneIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::LaneIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, :barcode_prefix ] ) }
      end
    end

    def related_resources
      ['parents']
    end
  end
  renders_model(::Lane)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:barcode)
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:external_release)
  map_attribute_to_json_attribute(:two_dimensional_barcode)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:barcode_prefix) do
    map_attribute_to_json_attribute(:prefix, 'barcode_prefix')
  end

  self.related_resources = [ :requests ]
end
