#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class Api::BatchIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::BatchIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes( [ :uuid_object, :user, :assignee, { :pipeline => :uuid_object }] ) }
      end
    end
  end

  renders_model(::Batch)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:qc_state)
  map_attribute_to_json_attribute(:production_state)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:user) do
    map_attribute_to_json_attribute(:login, 'created_by')
  end

  with_association(:assignee) do
    map_attribute_to_json_attribute(:login, 'assigned_to')
  end

  with_association(:pipeline) do
    map_attribute_to_json_attribute(:name, 'pipeline_name')
    map_attribute_to_json_attribute(:uuid, 'pipeline_uuid')
    map_attribute_to_json_attribute(:id,   'pipeline_internal_id')
  end
end
