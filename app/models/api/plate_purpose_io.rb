class Api::PlatePurposeIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::PlatePurposeIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      "plate_purpose"
    end
  end

  renders_model(::PlatePurpose)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
end
