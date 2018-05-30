# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

Given(/^Pipeline "([^\"]*)" and a setup for submitted at$/) do |name|
  pipeline = Pipeline.find_by(name: name) or raise StandardError, "Cannot find pipeline '#{name}'"
  asset_type = pipeline_name_to_asset_type(name)
  request_type = pipeline.request_types.detect { |rt| !rt.deprecated }
  metadata = FactoryBot.create :"request_metadata_for_#{request_type.key}"
  asset = FactoryBot.create(asset_type)
  request = FactoryBot.create :request_with_submission, request_type: request_type, asset: asset, request_metadata: metadata
  if request.asset.is_a?(Well)
    request.asset.plate = FactoryBot.create(:plate) if request.asset.plate.nil?
  end

  request.asset.save!
end
