#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class Api::BatchRequestIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::BatchRequestIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([ :uuid_object, { :request => [ :uuid_object, :request_type, { :asset => :uuid_object }, { :target_asset => :uuid_object } ] }, { :batch => :uuid_object } ] ) }
      end
    end
  end
  renders_model(::BatchRequest)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:batch) do
    map_attribute_to_json_attribute(:uuid, 'batch_uuid')
    map_attribute_to_json_attribute(:id,   'batch_internal_id')
  end

  with_association(:request) do
    map_attribute_to_json_attribute(:uuid, 'request_uuid')
    map_attribute_to_json_attribute(:id,   'request_internal_id')

    with_association(:request_type) do
      map_attribute_to_json_attribute(:name, 'request_type')
    end

    with_association(:asset) do
      map_attribute_to_json_attribute(:uuid, 'source_asset_uuid')
      map_attribute_to_json_attribute(:id,   'source_asset_internal_id')
      map_attribute_to_json_attribute(:name, 'source_asset_name')
    end

    with_association(:target_asset) do
      map_attribute_to_json_attribute(:uuid, 'target_asset_uuid')
      map_attribute_to_json_attribute(:id,   'target_asset_internal_id')
      map_attribute_to_json_attribute(:name, 'target_asset_name')
    end
  end
end
