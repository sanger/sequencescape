# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

Given /^Pipeline "([^"]*)" and a setup for 6218053$/ do |name|
  pipeline = Pipeline.find_by(name: name) or raise StandardError, "Cannot find pipeline '#{name}'"
  asset_type = pipeline_name_to_asset_type(name)
  request_type = pipeline.request_types.detect { |rt| !rt.deprecated }
  metadata = FactoryGirl.create :"request_metadata_for_#{request_type.key}"
  request  = FactoryGirl.create :request, request_type: request_type, asset: FactoryGirl.create(asset_type), request_metadata: metadata
  request.asset.location = pipeline.location
  request.asset.save!
end
