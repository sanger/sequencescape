# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

class Api::OrderIO < Api::Base
  renders_model(::Order)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id, 'internal_id')
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  map_attribute_to_json_attribute(:template_name)
  map_attribute_to_json_attribute(:comments)

  # with_association(:submission) do
  # map_attribute_to_json_attribute(:uuid  , 'submission_uuid')
  # map_attribute_to_json_attribute(:id  , 'submission_internal_id')
  # map_attribute_to_json_attribute(:name  , 'submission_name')
  # end

  with_association(:project) do
    map_attribute_to_json_attribute(:uuid, 'project_uuid')
    map_attribute_to_json_attribute(:id, 'project_internal_id')
    map_attribute_to_json_attribute(:name, 'project_name')
  end

  with_association(:study) do
    map_attribute_to_json_attribute(:uuid, 'study_uuid')
    map_attribute_to_json_attribute(:id, 'study_internal_id')
    map_attribute_to_json_attribute(:name, 'study_name')
  end

  with_association(:submission) do
    map_attribute_to_json_attribute(:uuid, 'submission_uuid')
    map_attribute_to_json_attribute(:id, 'submission_internal_id')
    # map_attribute_to_json_attribute(:name  , 'submission_name')
  end

  with_association(:user) do
    map_attribute_to_json_attribute(:login, 'created_by')
  end

  extra_json_attributes do |object, json_attributes|
    json_attributes['asset_uuids'] = object.asset_uuids
    json_attributes['request_options'] = object.request_options_structured unless object.request_options_structured.blank?
  end
end
