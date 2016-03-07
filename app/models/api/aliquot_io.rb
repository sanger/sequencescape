#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class Api::AliquotIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::AliquotIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([
            :uuid_object,
            { :sample => :uuid_object} ,
            { :study => :uuid_object },
            { :project => :uuid_object },
            { :tag => :uuid_object },
            { :library => :uuid_object },
            { :receptacle => :uuid_object }
          ])}
      end
    end
  end
  renders_model(::Aliquot)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  map_attribute_to_json_attribute(:insert_size_from)
  map_attribute_to_json_attribute(:insert_size_to)
  map_attribute_to_json_attribute('library_type')

  with_association(:study) do
    map_attribute_to_json_attribute(:url , 'study_url')
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
    map_attribute_to_json_attribute(:id  , 'study_internal_id')
  end

  with_association(:project) do
    map_attribute_to_json_attribute(:url , 'project_url')
    map_attribute_to_json_attribute(:uuid, 'project_uuid')
    map_attribute_to_json_attribute(:id  , 'project_internal_id')
  end

  with_association(:sample) do
    map_attribute_to_json_attribute(:url , 'sample_url')
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
    map_attribute_to_json_attribute(:id  , 'sample_internal_id')
  end

  with_association(:tag) do
    map_attribute_to_json_attribute(:url , 'tag_url')
    map_attribute_to_json_attribute(:uuid, 'tag_uuid')
    map_attribute_to_json_attribute(:id  , 'tag_internal_id')
  end
  with_association(:receptacle) do
    map_attribute_to_json_attribute(:url , 'receptacle_url')
    map_attribute_to_json_attribute(:uuid, 'receptacle_uuid')
    map_attribute_to_json_attribute(:id  , 'receptacle_internal_id')
    map_attribute_to_json_attribute(:type  , 'receptacle_type')
  end

  with_association(:library) do
    map_attribute_to_json_attribute(:url , 'library_url')
    map_attribute_to_json_attribute(:uuid, 'library_uuid')
    map_attribute_to_json_attribute(:id, 'library_internal_id')
  end

  with_association(:bait_library) do
    map_attribute_to_json_attribute(:name,                'bait_library_name')
    map_attribute_to_json_attribute(:target_species,      'bait_library_target_species')
    map_attribute_to_json_attribute(:supplier_identifier, 'bait_library_supplier_identifier')
    with_association(:bait_library_supplier) do
      map_attribute_to_json_attribute(:name, 'bait_library_supplier_name')
    end
  end
  #self.related_resources = [ :library_tubes, :requests ]
end
