# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Api::EventIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::EventIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([:uuid_object, { eventful: :uuid_object }]) }
        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      'event'
    end

    def render_class
      Api::EventIO
    end
  end

  renders_model(::Event)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:message)
  map_attribute_to_json_attribute(:family)
  map_attribute_to_json_attribute(:identifier)
  map_attribute_to_json_attribute(:location)
  map_attribute_to_json_attribute(:actioned)
  map_attribute_to_json_attribute(:content)
  map_attribute_to_json_attribute(:created_by)
  map_attribute_to_json_attribute(:of_interest_to)
  map_attribute_to_json_attribute(:descriptor_key)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:created_at)

  with_association(:eventful) do
    map_attribute_to_json_attribute(:uuid, 'eventful_uuid')
    map_attribute_to_json_attribute(:id,   'eventful_internal_id')

    extra_json_attributes do |object, json_attributes|
      json_attributes['eventful_type'] = object.class.name.tableize
    end
  end
end
