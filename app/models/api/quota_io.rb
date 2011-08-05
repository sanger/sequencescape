class Api::QuotaIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::QuotaIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        named_scope :including_associations_for_json, { :include => [ :uuid_object, { :project => :uuid_object }, :request_type ] }
      end
    end
  end

  renders_model(::Quota)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:limit, 'quota_limit')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:request_type) do
    map_attribute_to_json_attribute(:name, 'request_type')
  end

  with_association(:project) do
    map_attribute_to_json_attribute(:id  , 'project_internal_id')
    map_attribute_to_json_attribute(:uuid, 'project_uuid')
    map_attribute_to_json_attribute(:name, 'project_name')
  end
end
