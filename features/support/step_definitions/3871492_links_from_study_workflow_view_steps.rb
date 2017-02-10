# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

Given /^study "([^"]+)" has a registered sample "([^"]+)"$/ do |study_name, sample_name|
  study  = Study.find_by!(name: study_name)
  sample = study.samples.create!(name: sample_name)
  st = SampleTube.create!.tap { |sample_tube| sample_tube.aliquots.create!(sample: sample, study: study) }

  FactoryHelp::submission(
    study: study,
    assets: [st],
    workflow: @current_user.workflow,
    state: 'ready'
  )
end

Given /^study "([^"]+)" has made the following "([^"]+)" requests:$/ do |study_name, request_type, table|
  study        = Study.find_by!(name: study_name)
  request_type = RequestType.find_by!(name: request_type)

  table.hashes.each do |row|
    state, asset_name, sample_name = row['state'], row['asset'], row['sample']
    asset  = Asset.find_by!(name: asset_name)
    sample = Sample.find_by!(name: sample_name)

    if asset.respond_to?(:aliquots)
      asset.aliquots.each do |aliquot|
        aliquot.update_attributes!(study_id: study.id)
      end
    end

    count = (row['count'] == 'none') ? 0 : row['count'].to_i
    if count == 0
      requests = study.requests.for_asset_id(asset.id).for_state(state)
      requests.select { |r| r.samples.include?(sample) }.map(&:destroy) if requests.present?
    else
      count.to_i.times do |_index|
        FactoryGirl.create(
          :request,
          request_type: request_type,
          user: @current_user, workflow: @current_user.workflow,
          study: study, asset: asset, state: state
        )
      end
    end
  end
end

When /^I activate the "([^"]+)" tab$/ do |tab_name|
  step(%Q{I follow "#{tab_name}"})
end

Then /^the (pending|started|passed|failed|cancelled) requests for "([^"]+)" should not be a link$/ do |status, asset_name|
  assert_equal false, page.has_css?("a[title='#{asset_name} #{status}']"), "Link '#{asset_name} #{status}' exists"
end

When /^I view the (pending|started|passed|failed|cancelled) requests for "([^"]+)"$/ do |status, asset_name|
  step(%Q{I follow "#{asset_name} #{status}"})
end
