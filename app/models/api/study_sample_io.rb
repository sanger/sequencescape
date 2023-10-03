# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {StudySample}
# Historically used to be v0.5 API
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

        scope :including_associations_for_json,
              lambda { includes([:uuid_object, { study: :uuid_object }, { sample: :uuid_object }]) }
      end
    end
  end

  renders_model(::StudySample)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:sample) do
    map_attribute_to_json_attribute(:id, 'sample_internal_id')
    map_attribute_to_json_attribute(:uuid, 'sample_uuid')
  end

  with_association(:study) do
    map_attribute_to_json_attribute(:id, 'study_internal_id')
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
  end
end
