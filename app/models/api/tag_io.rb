#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class Api::TagIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::TagIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([ :uuid_object, { :tag_group => [:uuid_object] } ]) }
      end
    end
  end

  renders_model(::Tag)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:oligo, 'expected_sequence')
  map_attribute_to_json_attribute(:map_id)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:tag_group) do
    map_attribute_to_json_attribute(:name, 'tag_group_name')
    map_attribute_to_json_attribute(:uuid, 'tag_group_uuid')
    map_attribute_to_json_attribute(:id  , 'tag_group_internal_id')
  end
end
