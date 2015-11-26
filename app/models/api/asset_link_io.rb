#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::AssetLinkIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::AssetLinkIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, { :ancestor => :uuid_object }, { :descendant  => :uuid_object }]) }
      end
    end
  end
  renders_model(::AssetLink)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:ancestor) do
    map_attribute_to_json_attribute(:uuid, 'ancestor_uuid')
    map_attribute_to_json_attribute(:id,   'ancestor_internal_id')

    extra_json_attributes do |object, json_attributes|
      json_attributes['ancestor_type'] = object.sti_type.tableize unless object.nil?
    end
  end

  with_association(:descendant) do
    map_attribute_to_json_attribute(:uuid, 'descendant_uuid')
    map_attribute_to_json_attribute(:id,   'descendant_internal_id')

    extra_json_attributes do |object, json_attributes|
      json_attributes['descendant_type'] = object.sti_type.tableize unless object.nil?
    end
  end
end
