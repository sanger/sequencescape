# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given /^study "([^\"]+)" has an asset group called "([^\"]+)" with (\d+) wells$/ do |study_name, group_name, count|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find the study #{study_name.inspect}"

  plate = FactoryGirl.create(:plate)
  study.asset_groups.create!(name: group_name).tap do |asset_group|
    asset_group.assets << (1..count.to_i).map { |index| FactoryGirl.create(:well, plate: plate, map: Map.map_96wells[index - 1]) }
  end
end

Given /^I have a "([^\"]+)" submission of asset group "([^\"]+)" under project "([^\"]+)"$/ do |template_name, group_name, project_name|
  asset_group = AssetGroup.find_by(name: group_name) or raise StandardError, "Cannot find the asset group #{group_name.inspect}"

  # NOTE: Working with Submission from the code at this point is a nightmare, so use the UI!
  step(%Q{I am on the show page for study "#{asset_group.study.name}"})
  step('I follow "Create Submission"')
  step(%Q{I select "#{template_name}" from "Template"})
  step('I press "Next"')
  step(%Q{I select "#{project_name}" from "Select a financial project"})
  step(%Q{I select "#{group_name}" from "Select a group to submit"})
  step('I create the order and submit the submission')

  step('all pending delayed jobs are processed')
end

Given /^all assets for requests in the "([^\"]+)" pipeline have been scanned into the lab$/ do |name|
  pipeline = Pipeline.find_by!(name: name)
  pipeline.requests.each { |request| request.asset.labware.update_attributes!(location: pipeline.location) }
end

When /^I check "([^\"]+)" for (\d+) to (\d+)$/ do |label_root, start, finish|
  (start.to_i..finish.to_i).each do |i|
    step(%Q{I check "#{label_root} #{i}"})
  end
end

Given /^all of the requests in the "([^\"]+)" pipeline are in the "([^\"]+)" state$/ do |name, state|
  pipeline = Pipeline.find_by(name: name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  pipeline.requests.each { |request| request.update_attributes!(state: state) }
end

Then /^the inbox should contain (\d+) requests?$/ do |count|
  with_scope('#pipeline_inbox') do
    if page.respond_to? :should
      page.should have_xpath('//td[contains(@class, "request")]', count: count.to_i)
    else
      assert page.has_xpath?('//td[contains(@class, "request")]', count: count.to_i), 'Page missing xpath'
    end
  end
end

Then /^the batch (input|output) asset table should be:$/ do |name, expected_table|
  expected_table.diff!(table(fetch_table("##{name}_assets")))
end

Then /^the batch input asset table should have 1 row with (\d+) wells$/ do |count|
  Cucumber::Ast::Table.new([{ 'Wells' => count }]).diff!(table(fetch_table("##{name}_assets")))
end

Given /^the plate template "([^\"]+)" exists$/ do |name|
  FactoryGirl.create(:plate_template, name: name)
end

# This is a complete hack to get this to work: it knows where the wells are and goes to get them.  It knows
# where the empty cells are and it goes and gets them too.
When /^I drag (\d+) wells to the scratch pad$/ do |count|
  # The new style moves the scratch pad outside the viewport, we enlarge the viewport for this test
  page.driver.resize(1440, 2000)
  dest_pad = find('#scratch_pad tr:first-child td:first-child') or raise StandardError, 'Could not find scratch pad'

  (1..count.to_i).each do |index|
    src_well = first('#plate_1 td.colour0') or raise StandardError, "Could not find the #{index} well in the plate"
    src_id = src_well[:id]
    src_well.drag_to(dest_pad)

    # Ugh. While find is supposed to wait for an element, it doesn't appear to
    # We still need to sleep.
    sleep(1)
    find("#scratch_pad ##{src_id}")
  end
end

#########################################################################################################
# These are the steps for the general checking of the batch request behaviour.  Note that you probably
# shouldn't be merging these steps into generic ones as they are fairly specific.
#########################################################################################################
def build_batch_for(name, count)
  pipeline           = Pipeline.find_by(name: name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  submission_details = yield(pipeline)

  user = FactoryGirl.create(:user)

  assets = Array.new(count.to_i) do
    asset_attributes = {}
    if submission_details.key?(:holder_type)
      asset_attributes[:plate] = FactoryGirl.create(submission_details[:holder_type], location_id: pipeline.location_id)
      asset_attributes[:map_id] = 1
    else
      asset_attributes[:location_id] = pipeline.location_id
    end
    FactoryGirl.create(submission_details[:asset_type], asset_attributes)
  end

  wf = pipeline.request_types.last.workflow
  rts = pipeline.request_types.reject(&:deprecated?).map(&:id)
  # Build a submission that should end up in the appropriate inbox, once all of the assets have been
  # deemed as scanned into the lab!
  LinearSubmission.build!(
    study: FactoryGirl.create(:study),
    project: FactoryGirl.create(:project),
    workflow: wf,
    user: user,

    # Setup the assets so that they have samples and they are scanned into the correct lab.
    assets: assets,
    request_types: rts,

    # Request parameter options
    request_options: submission_details[:request_options]
  )
  step('all pending delayed jobs are processed')

  # step build a batch that will hold all of these requests, ensuring that it appears to be at least started
  # in some form.
  requests = pipeline.requests.ready_in_storage.all
  raise StandardError, "Pipeline has #{requests.size} requests waiting rather than #{count}" if requests.size != count.to_i
  batch = Batch.create!(pipeline: pipeline, user: user, requests: requests)
end

def requests_for_pipeline(name, count)
  pipeline          = Pipeline.find_by(name: name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  requests_in_inbox = pipeline.requests.ready_in_storage.full_inbox.all

  # There should be requests in the inbox and they should be clones of original requests.
  assert_equal(count.to_i, requests_in_inbox.size, "Unexpected number of requests in the #{name.inspect} inbox")
  yield(requests_in_inbox)
end

# Bad, I know, but it gets the job done for the genotyping pipelines!
Given /^the batch and all its requests are pending$/ do
  batch = Batch.first or raise StandardError, 'There appears to be no batches!'
  batch.update_attributes!(state: 'pending')
  batch.requests.each { |r| r.update_attributes!(state: 'pending') }
end

SEQUENCING_PIPELINES = [
  'Cluster formation SE',
  'Cluster formation PE',
  'Cluster formation PE (no controls)',
  'Cluster formation PE (spiked in controls)',
  'Cluster formation SE HiSeq',
  'Cluster formation SE HiSeq (no controls)',
  'HiSeq Cluster formation PE (no controls)'
].map(&Regexp.method(:escape)).join('|')

Given /^I have a batch with (\d+) requests? for the "(#{SEQUENCING_PIPELINES})" pipeline$/ do |count, name|
  build_batch_for(name, count.to_i) do |pipeline|
    {
      asset_type: :library_tube,
      request_options: {
        fragment_size_required_from: 1,
        fragment_size_required_to: 100,
        read_length: pipeline.request_types.last.request_type_validators.find_by(request_option: 'read_length').valid_options.first
      }
    }
  end
end

Then /^the (\d+) requests should be in the "(#{SEQUENCING_PIPELINES})" pipeline inbox$/ do |count, name|
  requests_for_pipeline(name, count.to_i) do |requests_in_inbox|
    requests_in_inbox.each do |request|
      assert(request.comments.any? { |c| c.description =~ /^Automatically created clone of request/ }, "Request #{request.id} is not a clone!")
    end
  end
end

LIBRARY_CREATION_PIPELINES = [
  'Library preparation',
  'Illumina-C Library preparation',
  'Illumina-B Library preparation',
  'Illumina-A Library preparation',
  'MX Library creation',
  'MX Library Preparation [NEW]',
  'Illumina-B MX Library Preparation',
  'Pulldown library preparation'
].map(&Regexp.method(:escape)).join('|')

Given /^I have a batch with (\d+) requests? for the "(#{LIBRARY_CREATION_PIPELINES})" pipeline$/ do |count, name|
  build_batch_for(name, count.to_i) do |_pipeline|
    {
      asset_type: :sample_tube,
      request_options: {
        fragment_size_required_from: 1,
        fragment_size_required_to: 100,
        library_type: 'Standard'
      }
    }
  end
end

Then /^the (\d+) requests should be in the "(#{LIBRARY_CREATION_PIPELINES})" pipeline inbox$/ do |count, name|
  requests_for_pipeline(name, count.to_i) do |requests_in_inbox|
    assert(Batch.first.requests.empty?, "There are still requests present in the #{name.inspect} batch")
    assert(requests_in_inbox.all? { |r| r.target_asset.nil? }, "There are #{name.inspect} requests with target assets")
  end
end

GENOTYPING_PIPELINES = [
  'Manual Quality Control',
  'DNA QC',
  'Cherrypick',
  'Genotyping'
].map(&Regexp.method(:escape)).join('|')

Given /^I have a batch with (\d+) requests? for the "(#{GENOTYPING_PIPELINES})" pipeline$/ do |count, name|
  build_batch_for(name, count.to_i) do |_pipeline|
    {
      asset_type: :well,
      holder_type: :plate
    }
  end
end

# Even though the other test says that there is one request visible in the inbox and we have to look at
# the wells, this one has 5 requests visible in the inbox because the wells are from different plates.
Then /^the (\d+) requests should be in the "(#{GENOTYPING_PIPELINES})" pipeline inbox$/ do |count, name|
  requests_for_pipeline(name, count.to_i) do |requests_in_inbox|
    # Not really much else to check here, they should just appear!
  end
end
