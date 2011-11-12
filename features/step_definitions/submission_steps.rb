Given /^I have a plate in study "([^"]*)" with samples with known sanger_sample_ids$/ do |study_name|
  study = Study.find_by_name(study_name)
  plate = PlatePurpose.stock_plate_purpose.create!(true, :barcode => "1234567", :location => Location.find_by_name("Sample logistics freezer"))
  1.upto(4) do |i|
    Well.create!(:plate => plate, :map_id => i).aliquots.create!(:sample => Sample.create!(:name => "Sample_#{i}", :sanger_sample_id => "ABC_#{i}"))
  end
end

Given /^I have an empty submission$/ do
  Factory(:submission_without_order)
end

Given /^all submissions have been built$/ do
  Submission.all.map(&:built!)
  Given "all pending delayed jobs are processed"
end

#Given /^I have a submission created with the following details based on the template "([^\"]+)":$/ do |name, details|
#  template = SubmissionTemplate.find_by_name(name) or raise StandardError, "Cannot find submission template #{name.inspect}"
#  order_attributes, submission_attributes = details.rows_hash.partition { |k,_| k != 'state' }
#  order_attributes.map! do |k,v| 
#    v =
#      case k
#      when 'asset_group_name' then v
#      when 'request_options' then Hash[v.split(',').map { |p| p.split(':').map(&:strip) }]
#      when 'assets' then Uuid.with_external_id(v.split(',').map(&:strip)).all.map(&:resource)
#      else Uuid.include_resource.with_external_id(v).first.try(:resource) 
#      end
#    [ k.to_sym, v ]
#  end
#
#  order = template.create_with_submission!({ :user => User.first }.merge(Hash[order_attributes]))
#  order.submission.update_attributes!(Hash[submission_attributes]) unless submission_attributes.empty?
#end

When /^the state of the submission with UUID "([^"]+)" is "([^"]+)"$/ do |uuid, state|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  submission.update_attributes!(:state => state)
end


Then /^there should be no submissions to be processed$/ do
  Then %Q{there should be no delayed jobs to be processed}
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
  Factory(:request_type, :name => name)
end

Then /^the (library tube) "([^\"]+)" should have (\d+) "([^\"]+)" requests$/ do |asset_model, asset_name, count, request_type_name|
  asset        = asset_model.gsub(/\s+/, '_').classify.constantize.find_by_name(asset_name) or raise StandardError, "Could not find #{asset_model} #{asset_name.inspect}"
  request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Could not find request type #{request_type_name.inspect}"
  assert_equal(count.to_i, asset.requests.count(:conditions => { :request_type_id => request_type.id }), "Number of #{request_type_name.inspect} requests incorrect")
end

def submission_in_state(state, attributes = {})
  study    = Study.first or raise StandardError, "There are no studies!"
  workflow = Submission::Workflow.first or raise StandardError, "There are no workflows!"
  submission = Factory::submission({ :asset_group_name => 'Faked to prevent empty asset errors' }.merge(attributes).merge(:study => study, :workflow => workflow))
  submission.state = state
  submission.save(false)
end

Given /^I have a submission in the "([^\"]+)" state$/ do |state|
  submission_in_state(state)
end

Given /^I have a submission in the "failed" state with message "([^\"]+)"$/ do |message|
  submission_in_state('failed', :message => message)
end

# These are the sensible default values for requests, which later get bound to the request types
# they make sense for.  The sequencing defaults do not need fragment size information as this is part
# of the library that is being sequenced and the UI will populate that information.
SENSIBLE_DEFAULTS_STANDARD = {
  'Fragment size required (from)' => 100,
  'Fragment size required (to)'   => 200,
  'Library type'                  => lambda { |step, field| step.select('Standard', :from => field) },
  'Read length'                   => 76
}
SENSIBLE_DEFAULTS_FOR_SEQUENCING = {
  'Read length'                   => lambda { |step, field| step.select('76', :from => field) }
}
SENSIBLE_DEFAULTS_HISEQ = SENSIBLE_DEFAULTS_FOR_SEQUENCING.merge(
  'Read length' => lambda { |step, field| step.select('100', :from => field) }
)
SENSIBLE_DEFAULTS_FOR_REQUEST_TYPE = {
  # Non-HiSeq defaults
  "Library creation"             => SENSIBLE_DEFAULTS_STANDARD,
  "Multiplexed library creation" => SENSIBLE_DEFAULTS_STANDARD,
  "Pulldown library creation"    => SENSIBLE_DEFAULTS_STANDARD,
  "Single ended sequencing"      => SENSIBLE_DEFAULTS_FOR_SEQUENCING,
  "Paired end sequencing"        => SENSIBLE_DEFAULTS_FOR_SEQUENCING,

  # HiSeq defaults
  "Single ended hi seq sequencing" => SENSIBLE_DEFAULTS_HISEQ,
  "HiSeq Paired end sequencing"    => SENSIBLE_DEFAULTS_HISEQ,

  # PacBio defaults
  "PacBio Sample Prep" => {}
}

def with_request_type_scope(name, &block)
  request_type = RequestType.find_by_name(name) or raise StandardError, "Cannot find request type #{name.inspect}"
  with_scope("#request_type_options_for_#{request_type.id}", &block)
end

When /^I fill in the request fields with sensible values for "([^\"]+)"$/ do |name|
  with_request_type_scope(name) do
    SENSIBLE_DEFAULTS_FOR_REQUEST_TYPE[name].each do |field, value|
      value.is_a?(Proc) ? value.call(self, field) : fill_in(field, :with => value)
    end
  end
end

When /^I fill in "([^\"]+)" with "([^\"]+)" for the "([^\"]+)" request type$/ do |name, value, type|
  with_request_type_scope(type) do
    fill_in(name, :with => value)
  end
end

When /^I select "([^\"]+)" from "([^\"]+)" for the "([^\"]+)" request type$/ do |value, name, type|
  with_request_type_scope(type) do
    select(value, :from => name)
  end
end

Then /^the source asset of the last "([^\"]+)" request should be a "([^\"]+)"$/ do |request_type_name, asset_type|
  request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Cannot find request type #{request_type_name.inspect}"
  request      = request_type.requests.last or raise StandardError, "There are no #{request_type_name.inspect} requests!"
  assert_equal(asset_type.gsub(/\s+/, '_').classify.constantize, request.asset.class, "Source asset is of invalid type")
end

Given /^the last submission wants (\d+) runs of the "([^\"]+)" requests$/ do |count, type|
  submission   = Submission.last or raise StandardError, "There appear to be no submissions"
  request_type = RequestType.find_by_name(type) or raise StandardError, "Cannot find request type #{type.inspect}"
  submission.request_options              ||= {}
  submission.request_options[:multiplier] ||= Hash[submission.request_types.map { |t| [t,1] }]
  submission.request_options[:multiplier][request_type.id.to_i] = count.to_i
  submission.save!
end

Given /^the sample tubes are part of submission "([^"]*)"$/ do |submission_uuid|
  submission = Uuid.find_by_external_id(submission_uuid).resource or raise StandardError, "Couldnt find object for UUID"
  Asset.all.map{ |asset| submission.order.assets << asset } 
end

Then /^I create the order and submit the submission/ do
  Then %q{I choose "build_submission_yes"}
  Then %q{I press "Create Order"}
  And %q{I press "Submit"}
end
