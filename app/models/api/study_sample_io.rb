#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::StudySampleIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::StudySampleIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, {:study => :uuid_object }, {:sample => :uuid_object } ]) }
      end
    end
  end

  renders_model(::StudySample)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:sample) do
    map_attribute_to_json_attribute(:id  , 'sample_internal_id')
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
  end

  with_association(:study) do
    map_attribute_to_json_attribute(:id  , 'study_internal_id')
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
  end

  self.related_resources = [ :samples, :studies ]
end
