# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Batch}
# Historically used to be v0.5 API
class Api::BatchIo < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::BatchIo
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json,
              lambda { includes([:uuid_object, :user, :assignee, { pipeline: :uuid_object }]) }
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

  with_association(:user) { map_attribute_to_json_attribute(:login, 'created_by') }

  with_association(:assignee) { map_attribute_to_json_attribute(:login, 'assigned_to') }

  with_association(:pipeline) do
    map_attribute_to_json_attribute(:name, 'pipeline_name')
    map_attribute_to_json_attribute(:uuid, 'pipeline_uuid')
    map_attribute_to_json_attribute(:id, 'pipeline_internal_id')
  end
end
