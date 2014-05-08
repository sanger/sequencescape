class Api::BillingEventIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::BillingEventIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        named_scope :including_associations_for_json, { :include => [ :uuid_object, { :project =>[ { :project_metadata => :budget_division }, :uuid_object ] }, { :request => [ :request_metadata, :request_type, :uuid_object ] } ] }
      end
    end
  end

  renders_model(::BillingEvent)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:kind)
  map_attribute_to_json_attribute(:entry_date)
  map_attribute_to_json_attribute(:created_by)
  map_attribute_to_json_attribute(:reference)
  map_attribute_to_json_attribute(:description)
  map_attribute_to_json_attribute(:quantity)

  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:created_at)

  with_association(:project) do
    map_attribute_to_json_attribute(:uuid, 'project_uuid')
    map_attribute_to_json_attribute(:id,   'project_internal_id')
    map_attribute_to_json_attribute(:name, 'project_name')

    with_association(:project_metadata) do
      with_association(:budget_division, :lookup_by => :name) do
        map_attribute_to_json_attribute(:name , 'project_division')
      end
      map_attribute_to_json_attribute(:project_cost_code, 'project_cost_code')
    end
  end

  with_association(:request) do
    map_attribute_to_json_attribute(:id, 'request_internal_id')
    map_attribute_to_json_attribute(:uuid, 'request_uuid')
    with_association(:request_type) do
      map_attribute_to_json_attribute(:name, 'request_type')
    end
    with_association(:request_metadata) do
      map_attribute_to_json_attribute(:read_length, 'price')
      map_attribute_to_json_attribute(:library_type, 'library_type')
      extra_json_attributes do |object, json_attributes|
        json_attributes["bait_library_type"] = BaitLibrary.find(object.bait_library_id).bait_library_type.name if object.bait_library_id.present?
      end
    end
  end
end
