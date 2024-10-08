# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {PlatePurpose}
# Historically used to be v0.5 API
class Api::PlatePurposeIo < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::PlatePurposeIo
      end
    end

    def self.included(base)
      base.class_eval { extend ClassMethods }
    end

    def json_root
      'plate_purpose'
    end
  end

  renders_model(::PlatePurpose)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
end
