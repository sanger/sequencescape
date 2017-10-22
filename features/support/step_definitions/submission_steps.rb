# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given /^I have a plate in study "([^"]*)" with samples with known sanger_sample_ids$/ do |study_name|
  study = Study.find_by(name: study_name)
  plate = PlatePurpose.stock_plate_purpose.create!(true, barcode: '1234567', location: Location.find_by(name: 'Sample logistics freezer'))
  1.upto(4) do |i|
    Well.create!(plate: plate, map_id: i).aliquots.create!(sample: Sample.create!(name: "Sample_#{i}", sanger_sample_id: "ABC_#{i}"))
  end
end

Given /^I have an empty submission$/ do
  FactoryGirl.create(:submission_without_order)
end

Given /^all submissions have been built$/ do
  Submission.all.map(&:built!)
  step 'all pending delayed jobs are processed'
end

When /^the state of the submission with UUID "([^"]+)" is "([^"]+)"$/ do |uuid, state|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  submission.update_attributes!(state: state)
end

Then /^there should be no submissions to be processed$/ do
  step 'there should be no delayed jobs to be processed'
end

Then /^the submission with UUID "([^\"]+)" is ready$/ do |uuid|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  assert(submission.ready?, "Submission is not ready (#{submission.state.inspect}: #{submission.message})")
end

Then /^the last submission has been submitted$/ do
  Submission.last.built!
end

Then /^the submission with UUID "([^"]+)" should have (\d+) "([^"]+)" requests?$/ do |uuid, count, name|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  requests   = submission.requests.select { |r| r.request_type.name == name }
  assert_equal(count.to_i, requests.size, "Unexpected number of #{name.inspect} requests")
end

Given /^the request type "([^\"]+)" exists$/ do |name|
  FactoryGirl.create(:request_type, name: name)
end

Then /^the (library tube) "([^\"]+)" should have (\d+) "([^\"]+)" requests$/ do |asset_model, asset_name, count, request_type_name|
  asset        = asset_model.gsub(/\s+/, '_').classify.constantize.find_by(name: asset_name) or raise StandardError, "Could not find #{asset_model} #{asset_name.inspect}"
  request_type = RequestType.find_by(name: request_type_name) or raise StandardError, "Could not find request type #{request_type_name.inspect}"
  assert_equal(count.to_i, asset.requests.where(request_type_id: request_type.id).count, "Number of #{request_type_name.inspect} requests incorrect")
end

def submission_in_state(state, attributes = {})
  study    = Study.first or raise StandardError, 'There are no studies!'
  workflow = Submission::Workflow.first or raise StandardError, 'There are no workflows!'
  submission = FactoryHelp::submission({ asset_group_name: 'Faked to prevent empty asset errors' }.merge(attributes).merge(study: study, workflow: workflow))
  submission.state = state
  submission.save(validate: false)
end

Given /^I have a submission in the "([^\"]+)" state$/ do |state|
  submission_in_state(state)
end

Given /^I have a submission in the "failed" state with message "([^\"]+)"$/ do |message|
  submission_in_state('failed', message: message)
end

# These are the sensible default values for requests, which later get bound to the request types
# they make sense for.  The sequencing defaults do not need fragment size information as this is part
# of the library that is being sequenced and the UI will populate that information.
SENSIBLE_DEFAULTS_STANDARD = {
  'Fragment size required (from)' => 100,
  'Fragment size required (to)'   => 200,
  'Library type'                  => ->(step, field) { step.select('Standard', from: field) },
  'Read length'                   => 76
}
SENSIBLE_DEFAULTS_FOR_SEQUENCING = {
  'Read length'                   => ->(step, field) { step.select('76', from: field) }
}
SENSIBLE_DEFAULTS_HISEQ = SENSIBLE_DEFAULTS_FOR_SEQUENCING.merge(
  'Read length' => ->(step, field) { step.select('100', from: field) }
)
SENSIBLE_DEFAULTS_FOR_REQUEST_TYPE = {
  # Non-HiSeq defaults
  'Library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Illumina-C Library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Multiplexed library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Pulldown library creation'    => SENSIBLE_DEFAULTS_STANDARD,
  'Single ended sequencing'      => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  'Paired end sequencing'        => SENSIBLE_DEFAULTS_FOR_SEQUENCING,

  # HiSeq defaults
  'Single ended hi seq sequencing' => SENSIBLE_DEFAULTS_HISEQ,
  'HiSeq Paired end sequencing'    => SENSIBLE_DEFAULTS_HISEQ,

  'Illumina-B Single ended sequencing'      => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  'Illumina-B Paired end sequencing'        => SENSIBLE_DEFAULTS_FOR_SEQUENCING,

  # HiSeq defaults
  'Illumina-B Single ended hi seq sequencing' => SENSIBLE_DEFAULTS_HISEQ,
  'Illumina-B HiSeq Paired end sequencing'    => SENSIBLE_DEFAULTS_HISEQ,

  # PacBio defaults
  'PacBio Library Prep' => {}
}

def with_request_type_scope(name, &block)
  request_type = RequestType.find_by(name: name) or raise StandardError, "Cannot find request type #{name.inspect}"
  with_scope("#request_type_options_for_#{request_type.id}", &block)
end

When /^I fill in the request fields with sensible values for "([^\"]+)"$/ do |name|
  with_request_type_scope(name) do
    SENSIBLE_DEFAULTS_FOR_REQUEST_TYPE[name].each do |field, value|
      value.is_a?(Proc) ? value.call(self, field) : fill_in(field, with: value)
    end
  end
end

When /^I fill in "([^\"]+)" with "([^\"]+)" for the "([^\"]+)" request type$/ do |name, value, type|
  with_request_type_scope(type) do
    fill_in(name, with: value)
  end
end

When /^I select "([^\"]+)" from "([^\"]+)" for the "([^\"]+)" request type$/ do |value, name, type|
  with_request_type_scope(type) do
    select(value, from: name)
  end
end

Then /^the source asset of the last "([^\"]+)" request should be a "([^\"]+)"$/ do |request_type_name, asset_type|
  request_type = RequestType.find_by(name: request_type_name) or raise StandardError, "Cannot find request type #{request_type_name.inspect}"
  request      = request_type.requests.last or raise StandardError, "There are no #{request_type_name.inspect} requests!"
  assert_equal(asset_type.gsub(/\s+/, '_').classify.constantize, request.asset.class, 'Source asset is of invalid type')
end

Given /^the last submission wants (\d+) runs of the "([^\"]+)" requests$/ do |count, type|
  submission   = Submission.last or raise StandardError, 'There appear to be no submissions'
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"
  submission.request_options              ||= {}
  submission.request_options[:multiplier] ||= Hash[submission.request_types.map { |t| [t, 1] }]
  submission.request_options[:multiplier][request_type.id.to_i] = count.to_i
  submission.save!
end

Given /^the sample tubes are part of submission "([^\"]*)"$/ do |submission_uuid|
  submission = Uuid.find_by(external_id: submission_uuid).resource or raise StandardError, 'Couldnt find object for UUID'
  Asset.all.map { |asset| submission.orders.first.assets << asset }
end

Then /^I create the order and submit the submission/ do
  step 'I choose "build_submission_yes"'
  step 'I press "Create Order"'
  step 'I press "Submit"'
end

Given /^I have a "([^\"]*)" submission with the following setup:$/ do |template_name, table|
  submission_template = SubmissionTemplate.find_by(name: template_name)
  params = table.rows_hash
  request_options = {}
  request_type_ids = submission_template.new_order.request_types

  params.each do |k, v|
    case k
    when /^multiplier#(\d+)/
      multiplier_hash = request_options[:multiplier]
      multiplier_hash = request_options[:multiplier] = {} unless multiplier_hash
      index = $1.to_i - 1
      multiplier_hash[request_type_ids[index].to_s] = v.to_i
    else
      key = k.underscore.gsub(/\W+/, '_')
      request_options[key] = v
    end
  end

  Submission.build!(
    template: submission_template,
    project: Project.find_by(name: params['Project']),
    study: Study.find_by(name: params['Study']),
    asset_group: AssetGroup.find_by(name: params['Asset Group']),
    workflow: Submission::Workflow.first,
    user: @current_user,
    request_options: request_options
  )

  # step(%Q{1 pending delayed jobs are processed})
end

Then /^the last submission should have a priority of (\d+)$/ do |priority|
  Submission.last.update_attributes!(priority: priority)
end

Given /^all the requests in the last submission are cancelled$/ do
  Submission.last.requests.each { |r| r.update_attributes!(state: 'cancelled') }
end
