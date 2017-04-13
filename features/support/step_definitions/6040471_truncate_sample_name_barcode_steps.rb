# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

When /^I print the following labels in the asset group$/ do |table|
  label_bitmaps = {}
  table.hashes.each do |h|
    field, value = ['Field', 'Value'].map { |k| h[k] }
    label_bitmaps[field] = Regexp.new(value)
  end

  stub_request(:post, LabelPrinter::PmbClient.print_job_url)
    .with(headers: LabelPrinter::PmbClient.headers)

  step('I follow "Print labels"')
  step('I select "xyz" from "Barcode Printer"')
  step('I press "Print"')

  assert_requested(:post, LabelPrinter::PmbClient.print_job_url,
    headers: LabelPrinter::PmbClient.headers, times: 1) do |req|
    h_body = JSON.parse(req.body)
    all_label_bitmaps = h_body['data']['attributes']['labels']['body'].first['main_label']
    label_bitmaps.all? { |k, v| v.match all_label_bitmaps[k] }
  end
end

Given /^I have an asset group "([^"]*)" which is part of "([^"]*)"$/ do |asset_group_name, study_name|
  AssetGroup.create!(name: asset_group_name, study: Study.find_by(name: study_name))
end

Given /^asset group "([^\"]*)" contains a "([^\"]*)" called "([^\"]*)"$/ do |asset_group_name, asset_type, asset_name|
  asset = eval(asset_type).create!(name: asset_name, barcode: '17')
  asset_group = AssetGroup.find_by(name: asset_group_name)
  asset_group.assets << asset
  asset_group.save!
end

Given /^the asset "([^\"]*)" has a sanger_sample_id of "([^\"]*)"$/ do |asset_id, sanger_sample_id|
  asset = Asset.find(asset_id)
  asset.aliquots.clear
  asset.aliquots.create!(sample: Sample.create!(name: 'Sample_123456', sanger_sample_id: sanger_sample_id))
end
