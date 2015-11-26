#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::RequestIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::RequestIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([
            :uuid_object,
            :request_type,
            :request_metadata,
            :user, {
              :asset => [
                :uuid_object,
                :barcode_prefix,
                { :primary_aliquot => { :sample => :uuid_object } }
              ],
              :target_asset => [
                :uuid_object,
                :barcode_prefix,
                { :primary_aliquot => { :sample => :uuid_object } }
              ],
              :initial_study =>:uuid_object,
              :initial_project => :uuid_object
            }
          ])}

        alias_method(:json_root, :url_name)
      end
    end

    def url_name
      "request" # frozen for subclass of the API
    end
  end

  renders_model(::Request)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:priority)


  extra_json_attributes do |object, json_attributes|
    json_attributes["read_length"]                 = object.request_metadata.read_length  if object.is_a?(SequencingRequest)
    json_attributes["library_type"]                = object.request_metadata.library_type if object.is_a?(LibraryCreationRequest)
    json_attributes["fragment_size_required_from"] = object.request_metadata.fragment_size_required_from   if object.request_metadata.respond_to?(:fragment_size_required_from)
    json_attributes["fragment_size_required_to"]   = object.request_metadata.fragment_size_required_to     if object.request_metadata.respond_to?(:fragment_size_required_to)
  end

  with_association(:user) do
    map_attribute_to_json_attribute(:login , 'user')
  end

  with_association(:submission) do
        map_attribute_to_json_attribute(:uuid, 'submission_uuid')
        map_attribute_to_json_attribute(:id  , 'submission_internal_id')
        map_attribute_to_json_attribute(:url , 'submission_url')
  end

  with_association(:initial_study) do
        map_attribute_to_json_attribute(:url , 'study_url')
        map_attribute_to_json_attribute(:uuid, 'study_uuid')
        map_attribute_to_json_attribute(:id  , 'study_internal_id')
        map_attribute_to_json_attribute(:name, 'study_name')
  end

  with_association(:initial_project) do
        map_attribute_to_json_attribute(:url , 'project_url')
        map_attribute_to_json_attribute(:uuid, 'project_uuid')
        map_attribute_to_json_attribute(:id  , 'project_internal_id')
        map_attribute_to_json_attribute(:name, 'project_name')
  end

  with_association(:asset) do
    map_attribute_to_json_attribute(:uuid                   , 'source_asset_uuid')
    map_attribute_to_json_attribute(:id                     , 'source_asset_internal_id')
    map_attribute_to_json_attribute(:name                   , 'source_asset_name')
    map_attribute_to_json_attribute(:barcode                , 'source_asset_barcode')
    map_attribute_to_json_attribute(:qc_state               , 'source_asset_state')
    map_attribute_to_json_attribute(:closed                 , 'source_asset_closed')
    map_attribute_to_json_attribute(:two_dimensional_barcode, 'source_asset_two_dimensional_barcode')

    extra_json_attributes do |object, json_attributes|
      json_attributes["source_asset_type"] = object.sti_type.tableize unless object.nil?
    end

    with_association(:primary_aliquot_if_unique) do
      with_association(:sample) do
        map_attribute_to_json_attribute(:uuid, 'source_asset_sample_uuid')
        map_attribute_to_json_attribute(:id  , 'source_asset_sample_internal_id')
      end
    end

    with_association(:barcode_prefix) do
      map_attribute_to_json_attribute(:prefix, 'source_asset_barcode_prefix')
    end
  end

  with_association(:target_asset) do
    map_attribute_to_json_attribute(:uuid                   , 'target_asset_uuid')
    map_attribute_to_json_attribute(:id                     , 'target_asset_internal_id')
    map_attribute_to_json_attribute(:name                   , 'target_asset_name')
    map_attribute_to_json_attribute(:barcode                , 'target_asset_barcode')
    map_attribute_to_json_attribute(:qc_state               , 'target_asset_state')
    map_attribute_to_json_attribute(:closed                 , 'target_asset_closed')
    map_attribute_to_json_attribute(:two_dimensional_barcode, 'target_asset_two_dimensional_barcode')

    extra_json_attributes do |object, json_attributes|
      json_attributes["target_asset_type"] = object.sti_type.tableize unless object.nil?
    end

    with_association(:primary_aliquot_if_unique) do
      with_association(:sample) do
        map_attribute_to_json_attribute(:uuid, 'target_asset_sample_uuid')
        map_attribute_to_json_attribute(:id  , 'target_asset_sample_internal_id')
      end
    end

    with_association(:barcode_prefix) do
      map_attribute_to_json_attribute(:prefix, 'target_asset_barcode_prefix')
    end
  end

  with_association(:request_type) do
    map_attribute_to_json_attribute(:name, 'request_type')
  end
end
