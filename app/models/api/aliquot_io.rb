# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Aliquot}
# Historically used to be v0.5 API
class Api::AliquotIo < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::AliquotIo
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json,
              -> do
                includes(
                  [
                    :uuid_object,
                    { sample: :uuid_object },
                    { study: :uuid_object },
                    { project: :uuid_object },
                    { tag: :uuid_object },
                    { library: :uuid_object },
                    { receptacle: :uuid_object }
                  ]
                )
              end
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
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
    map_attribute_to_json_attribute(:id, 'study_internal_id')
  end

  with_association(:project) do
    map_attribute_to_json_attribute(:uuid, 'project_uuid')
    map_attribute_to_json_attribute(:id, 'project_internal_id')
  end

  with_association(:sample) do
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
    map_attribute_to_json_attribute(:id, 'sample_internal_id')
  end

  with_association(:tag) do
    map_attribute_to_json_attribute(:uuid, 'tag_uuid')
    map_attribute_to_json_attribute(:id, 'tag_internal_id')
  end
  with_association(:receptacle) do
    map_attribute_to_json_attribute(:uuid, 'receptacle_uuid')
    map_attribute_to_json_attribute(:id, 'receptacle_internal_id')
    map_attribute_to_json_attribute(:type, 'receptacle_type')
  end

  with_association(:library) do
    map_attribute_to_json_attribute(:uuid, 'library_uuid')
    map_attribute_to_json_attribute(:id, 'library_internal_id')
  end

  with_association(:bait_library) do
    map_attribute_to_json_attribute(:name, 'bait_library_name')
    map_attribute_to_json_attribute(:target_species, 'bait_library_target_species')
    map_attribute_to_json_attribute(:supplier_identifier, 'bait_library_supplier_identifier')
    with_association(:bait_library_supplier) { map_attribute_to_json_attribute(:name, 'bait_library_supplier_name') }
  end
end
