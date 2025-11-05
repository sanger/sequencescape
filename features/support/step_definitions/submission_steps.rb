# frozen_string_literal: true

require './lib/submission_serializer'

Given /^I have an empty submission$/ do
  FactoryBot.create(:submission_without_order)
end

When /^the state of the submission with UUID "([^"]+)" is "([^"]+)"$/ do |uuid, state|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or
    raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  submission.update!(state:)
end

Then /^there should be no submissions to be processed$/ do
  step 'there should be no delayed jobs to be processed'
end

Then /^I have an ISC submission template$/ do
  submission_parameters = {
    name: 'Pulldown ISC - HiSeq Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_options: {
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'library_type' => 'Agilent Pulldown',
        'pre_capture_plex_level' => 8
      },
      request_types: %w[pulldown_isc illumina_a_hiseq_paired_end_sequencing]
    }
  }
  unless SubmissionTemplate.find_by(name: 'Pulldown ISC - HiSeq Paired end sequencing')
    SubmissionSerializer.construct!(submission_parameters)
  end
end

Then /^I have a WGS submission template$/ do
  submission_parameters = {
    name: 'Illumina-B - Pooled PATH - HiSeq Paired end sequencing',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: %w[illumina_b_shared illumina_b_pool illumina_b_hiseq_paired_end_sequencing],
      order_role: 'ILB PATH'
    }
  }
  unless SubmissionTemplate.find_by(name: 'Illumina-B - Pooled PATH - HiSeq Paired end sequencing')
    SubmissionSerializer.construct!(submission_parameters)
  end
end

Then /^I have a Tube submission template$/ do
  rt = FactoryBot.create :library_creation_request_type
  submission_parameters = {
    name: 'Example tube template',
    submission_class_name: 'LinearSubmission',
    product_catalogue: 'Generic',
    submission_parameters: {
      info_differential: 5,
      request_types: [rt.key],
      order_role: 'ILB PATH'
    }
  }
  unless SubmissionTemplate.find_by(name: 'Example tube template')
    SubmissionSerializer.construct!(submission_parameters)
  end
end

Then /^the submission with UUID "([^"]+)" is ready$/ do |uuid|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or
    raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  assert(submission.ready?, "Submission is not ready (#{submission.state.inspect}: #{submission.message})")
end

Then /^the last submission has been submitted$/ do
  Submission.last.built!
end

Then /^the submission with UUID "([^"]+)" should have (\d+) "([^"]+)" requests?$/ do |uuid, count, name|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or
    raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  requests = submission.requests.select { |r| r.request_type.name == name }
  assert_equal(count.to_i, requests.size, "Unexpected number of #{name.inspect} requests")
end

Given /^the request type "([^"]+)" exists$/ do |name|
  FactoryBot.create(:request_type, name:)
end

def submission_in_state(state, attributes = {})
  study = Study.first or raise StandardError, 'There are no studies!'
  submission =
    FactoryHelp.submission({ asset_group_name: 'Faked to prevent empty asset errors' }.merge(attributes).merge(study:))
  submission.state = state
  submission.save(validate: false)
end

Given /^I have a submission in the "([^"]+)" state$/ do |state|
  submission_in_state(state)
end

Given /^I have a submission in the "failed" state with message "([^"]+)"$/ do |message|
  submission_in_state('failed', message:)
end

# These are the sensible default values for requests, which later get bound to the request types
# they make sense for.  The sequencing defaults do not need fragment size information as this is part
# of the library that is being sequenced and the UI will populate that information.
SENSIBLE_DEFAULTS_STANDARD = {
  'Fragment size required (from)' => 100,
  'Fragment size required (to)' => 200,
  'Library type' => ->(step, field) { step.select('Standard', from: field) },
  'Read length' => 76
}.freeze
SENSIBLE_DEFAULTS_FOR_SEQUENCING = { 'Read length' => ->(step, field) { step.select('76', from: field) } }.freeze
SENSIBLE_DEFAULTS_HISEQ =
  SENSIBLE_DEFAULTS_FOR_SEQUENCING.merge('Read length' => ->(step, field) { step.select('100', from: field) })
SENSIBLE_DEFAULTS_FOR_REQUEST_TYPE = {
  # Non-HiSeq defaults
  'Library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Illumina-C Library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Multiplexed library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Pulldown library creation' => SENSIBLE_DEFAULTS_STANDARD,
  'Single ended sequencing' => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  'Paired end sequencing' => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  # HiSeq defaults
  'Single ended hi seq sequencing' => SENSIBLE_DEFAULTS_HISEQ,
  'HiSeq Paired end sequencing' => SENSIBLE_DEFAULTS_HISEQ,
  'Illumina-B Single ended sequencing' => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  'Illumina-B Paired end sequencing' => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  # HiSeq defaults
  'Illumina-B Single ended hi seq sequencing' => SENSIBLE_DEFAULTS_HISEQ,
  'Illumina-B HiSeq Paired end sequencing' => SENSIBLE_DEFAULTS_HISEQ
}.freeze

def with_request_type_scope(name, &)
  request_type = RequestType.find_by(name:) or raise StandardError, "Cannot find request type #{name.inspect}"
  with_scope("#request_type_options_for_#{request_type.id}", &)
end

When /^I fill in "([^"]+)" with "([^"]+)" for the "([^"]+)" request type$/ do |name, value, type|
  with_request_type_scope(type) { fill_in(name, with: value) }
end

When /^I select "([^"]+)" from "([^"]+)" for the "([^"]+)" request type$/ do |value, name, type|
  with_request_type_scope(type) { select(value, from: name) }
end

Given /^I have a "([^"]*)" submission with the following setup:$/ do |template_name, table|
  submission_template = SubmissionTemplate.find_by!(name: template_name)
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

  submission_template
    .create_with_submission!(
      project: Project.find_by(name: params['Project']),
      study: Study.find_by(name: params['Study']),
      asset_group: AssetGroup.find_by(name: params['Asset Group']),
      user: @current_user,
      request_options: request_options
    )
    .submission
    .built!

  # step(%Q{1 pending delayed jobs are processed})
end
Then /^the last submission should have a priority of (\d+)$/ do |priority|
  Submission.last.update!(priority:)
end

Given /^all the requests in the last submission are cancelled$/ do
  Submission.last.requests.each { |r| r.update!(state: 'cancelled') }
end
