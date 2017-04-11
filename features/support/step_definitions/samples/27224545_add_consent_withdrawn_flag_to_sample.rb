# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

Given /^the patient has withdrawn consent for "([^"]*)"$/ do |sample|
  Sample.find_by(name: sample).withdraw_consent
end

Given /^the study "([^"]*)" has the sample "([^"]*)" in a sample tube and asset group$/ do |study, sample|
  step(%Q{the study "#{study}" has an asset group called "#{sample}_group"})
  step(%Q{I have a sample called "#{sample}" with metadata})
  step(%Q{the sample "#{sample}" belongs to the study "#{study}"})
  step(%Q{a sample tube called "#{sample}_tube" with ID #{Asset.count + 1}})
  step(%Q{the sample "#{sample}" is in the sample tube "#{sample}_tube"})
  step(%Q{the sample tube "#{sample}_tube" is in the asset group "#{sample}_group"})
end

Given /^the study "([^"]*)" has the sample "([^"]*)" in a well and asset group$/ do |study, sample|
  step(%Q{the study "#{study}" has an asset group called "#{sample}_group"})
  step(%Q{I have a sample called "#{sample}" with metadata})
  step(%Q{the sample "#{sample}" belongs to the study "#{study}"})
  step(%Q{a well called "#{sample}_well" with ID #{Asset.count + 1}})
  step(%Q{the sample "#{sample}" is in the well "#{sample}_well"})
  step(%Q{the well "#{sample}_well" is in the asset group "#{sample}_group"})
end

Given /^I try to create a "([^\"]*)" order with the following setup:$/ do |template_name, table|
  submission_template = SubmissionTemplate.find_by(name: template_name)
  params = table.rows_hash
  request_options = {}
  params.each do |k, v|
    key = k.underscore.gsub(/\W+/, '_')
    request_options[key] = v
  end

  @order = submission_template.new_order(
    project: Project.find_by(name: params['Project']),
    study: Study.find_by(name: params['Study']),
    asset_group: AssetGroup.find_by(name: params['Asset Group']),
    workflow: Submission::Workflow.first,
    user: @current_user,
    request_options: request_options
  )
  @order.assets = [Asset.find_by(name: params['Asset'])] unless Asset.find_by(name: params['Asset']).nil?
end

Then /^the order should be invalid$/ do
  assert !@order.valid?
end
Then /^the order should be valid$/ do
  assert @order.valid?
end

Then /^the order should have errors$/ do
  assert @order.errors.count > 0
end
Then /^the order should not have errors$/ do
  assert @order.errors.count == 0
end

Then /^the last error should contain "([^\"]*)"$/ do |text|
  assert @order.errors.full_messages.include?(text)
end

Then /^the order should (not |)be built$/ do |n|
  assert Order.last == @order unless n == 'not '
  assert Order.last != @order if n == 'not '
end

Given /^batch "([^"]*)" in "Pulldown library preparation" has been setup with "([^"]*)" for feature 27224545$/ do |id, asset_group|
  pipeline    = Pipeline.find_by!(name: 'Pulldown library preparation')
  batch       = Batch.find(id)
  asset_group = AssetGroup.find_by(name: asset_group)
  requests = []
  asset_group.assets.each do |asset|
    target_asset = FactoryGirl.create :library_tube, sample: asset.samples.first, name: "#{asset.name}_target"
    request = pipeline.request_types.last.create!(
      asset: asset,
      target_asset: target_asset,
      request_metadata_attributes: { fragment_size_required_from: 100, fragment_size_required_to: 200, read_length: 76 }
    )
    request.save
    requests << request
  end
  batch.requests = requests
  batch.pipeline = pipeline
  batch.save!
end

Then /^the text of the as is XML element "([^"]+)" should be "([^"]+)"/ do |xpath, value|
  node = page.find(:xpath, xpath)
  assert node
  assert_equal value, node.text
end

When /^I get the XML for the batch "([^"]*)"$/ do |id|
  batch = Batch.find(id)
  visit(batch_path(batch, format: :xml))
end

When /^I try to save the order$/ do ||
  @order.save
end
