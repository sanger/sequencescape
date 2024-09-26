# frozen_string_literal: true

Given /^study "([^"]+)" has an asset group called "([^"]+)" with (\d+) wells$/ do |study_name, group_name, count|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find the study #{study_name.inspect}"

  plate = FactoryBot.create(:plate)
  study
    .asset_groups
    .create!(name: group_name)
    .tap do |asset_group|
      asset_group.assets << (1..count.to_i).map do |index|
        FactoryBot.create(:well, plate: plate, map: Map.map_96wells[index - 1])
      end
    end
end

When /^I check "([^"]+)" for (\d+) to (\d+)$/ do |label_root, start, finish|
  (start.to_i..finish.to_i).each { |i| step("I check \"#{label_root} #{i}\"") }
end

Then /^the inbox should contain (\d+) requests?$/ do |count|
  with_scope('#pipeline_inbox') do
    assert page.has_xpath?('//td[contains(@class, "request")]', count: count.to_i), 'Page missing xpath'
  end
end

Then /^the batch (input|output) asset table should be:$/ do |name, expected_table|
  expected_table.diff!(table(fetch_table("##{name}_assets")))
end

Given /^the plate template "([^"]+)" exists$/ do |name|
  FactoryBot.create(:plate_template, name:)
end

# This is a complete hack to get this to work: it knows where the wells are and goes to get them.  It knows
# where the empty cells are and it goes and gets them too.
When /^I drag (\d+) wells to the scratch pad$/ do |count|
  dest_pad = find('#scratch_pad tr:first-child td:first-child') or raise StandardError, 'Could not find scratch pad'

  (1..count.to_i).each do |index|
    src_well = first('#plate_1 td.colour0') or raise StandardError, "Could not find the #{index} well in the plate"
    src_id = src_well[:id]
    src_well.drag_to(dest_pad)
    within('#scratch_pad') { find("##{src_id}") }
  end
end

#########################################################################################################
# These are the steps for the general checking of the batch request behaviour.  Note that you probably
# shouldn't be merging these steps into generic ones as they are fairly specific.
#########################################################################################################
# rubocop:todo Metrics/MethodLength
def build_batch_for(name, count) # rubocop:todo Metrics/AbcSize
  pipeline = Pipeline.find_by(name:) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  submission_details = yield(pipeline)

  user = FactoryBot.create(:user)
  assets =
    Array.new(count.to_i) do
      asset_attributes = {}
      if submission_details.key?(:holder_type)
        asset_attributes[:plate] = FactoryBot.create(submission_details[:holder_type], :scanned_into_lab)
        asset_attributes[:map_id] = 1
      end
      FactoryBot.create(submission_details[:asset_type], :scanned_into_lab, asset_attributes)
    end
  rt_id = pipeline.request_types.active.first!.id

  # Build a submission that should end up in the appropriate inbox, once all of the assets have been
  # deemed as scanned into the lab!
  FactoryBot
    .create(
      :linear_submission,
      study: FactoryBot.create(:study),
      project: FactoryBot.create(:project),
      user: user,
      # Setup the assets so that they have samples and they are scanned into the correct lab.
      assets: assets,
      request_types: [rt_id],
      # Request parameter options
      request_options: submission_details[:request_options]
    )
    .submission
    .built!
  step('all pending delayed jobs are processed')

  # step build a batch that will hold all of these requests, ensuring that it appears to be at least started
  # in some form.
  requests = pipeline.requests.ready_in_storage.all
  if requests.size != count.to_i
    raise StandardError, "Pipeline has #{requests.size} requests waiting rather than #{count}"
  end

  batch = Batch.create!(pipeline:, user:, requests:)
end
# rubocop:enable Metrics/MethodLength

def requests_for_pipeline(name, count)
  pipeline = Pipeline.find_by(name:) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  requests_in_inbox = pipeline.requests.ready_in_storage.full_inbox.all

  # There should be requests in the inbox and they should be clones of original requests.
  assert_equal(count.to_i, requests_in_inbox.size, "Unexpected number of requests in the #{name.inspect} inbox")
  yield(requests_in_inbox)
end

# Bad, I know, but it gets the job done for the genotyping pipelines!
Given /^the batch and all its requests are pending$/ do
  batch = Batch.first or raise StandardError, 'There appears to be no batches!'
  batch.update!(state: 'pending')
  batch.requests.each { |r| r.update!(state: 'pending') }
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

Given /^I have a batch with (\d+) requests? for the "(#{SEQUENCING_PIPELINES})" pipeline$/o do |count, name|
  build_batch_for(name, count.to_i) do |pipeline|
    {
      asset_type: :library_tube,
      request_options: {
        fragment_size_required_from: 1,
        fragment_size_required_to: 100,
        read_length:
          pipeline.request_types.last.request_type_validators.find_by(request_option: 'read_length').valid_options.first
      }
    }
  end
end

Then /^the (\d+) requests should be in the "(#{SEQUENCING_PIPELINES})" pipeline inbox$/o do |count, name|
  requests_for_pipeline(name, count.to_i) do |requests_in_inbox|
    requests_in_inbox.each do |request|
      assert(
        request.comments.any? { |c| c.description =~ /^Automatically created clone of request/ },
        "Request #{request.id} is not a clone!"
      )
    end
  end
end

LIBRARY_CREATION_PIPELINES = [
  'Library preparation',
  'Illumina-C Library preparation',
  'Illumina-B Library preparation',
  'Illumina-A Library preparation',
  'MX Library creation',
  'Illumina-B MX Library Preparation'
].map(&Regexp.method(:escape)).join('|')

Given /^I have a batch with (\d+) requests? for the "(#{LIBRARY_CREATION_PIPELINES})" pipeline$/o do |count, name|
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

GENOTYPING_PIPELINES = ['Manual Quality Control', 'Cherrypick', 'Genotyping'].map(&Regexp.method(:escape)).join('|')

Given /^I have a batch with (\d+) requests? for the "(#{GENOTYPING_PIPELINES})" pipeline$/o do |count, name|
  build_batch_for(name, count.to_i) { |_pipeline| { asset_type: :well, holder_type: :plate } }
end

# Even though the other test says that there is one request visible in the inbox and we have to look at
# the wells, this one has 5 requests visible in the inbox because the wells are from different plates.
Then /^the (\d+) requests should be in the "(#{GENOTYPING_PIPELINES})" pipeline inbox$/o do |count, name|
  requests_for_pipeline(name, count.to_i) do |requests_in_inbox|
    # Not really much else to check here, they should just appear!
  end
end
