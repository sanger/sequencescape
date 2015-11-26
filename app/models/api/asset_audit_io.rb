#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::AssetAuditIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::AssetAuditIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, { :asset => [ :uuid_object, :barcode_prefix ] } ]) }
      end
    end
  end
  renders_model(::AssetAudit)

  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:message)
  map_attribute_to_json_attribute(:key)
  map_attribute_to_json_attribute(:created_by)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:witnessed_by)

  with_association(:asset) do
    map_attribute_to_json_attribute(:uuid, 'plate_uuid')
    map_attribute_to_json_attribute(:barcode, 'plate_barcode')

    with_association(:barcode_prefix) do
      map_attribute_to_json_attribute(:prefix, 'plate_barcode_prefix')
    end
  end

end
