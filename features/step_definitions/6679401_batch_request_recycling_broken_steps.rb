Given /^study "([^\"]+)" has an asset group called "([^\"]+)" with (\d+) wells$/ do |study_name, group_name, count|
  study = Study.find_by_name(study_name) or raise StandardError, "Cannot find the study #{study_name.inspect}"

  plate = Factory(:plate)
  study.asset_groups.create!(:name => group_name).tap do |asset_group|
    asset_group.assets << (1..count.to_i).map { |index| Factory(:well, :plate => plate, :map => Map.map_96wells[index-1] ) }
  end
end

Given /^I have a "([^\"]+)" submission of asset group "([^\"]+)" under project "([^\"]+)"$/ do |template_name, group_name, project_name|
  asset_group = AssetGroup.find_by_name(group_name) or raise StandardError, "Cannot find the asset group #{group_name.inspect}"

  # NOTE: Working with Submission from the code at this point is a nightmare, so use the UI!
  Given %Q{I am on the show page for study "#{asset_group.study.name}"}
  When %Q{I follow "Create Submission"}
  When %Q{I select "#{template_name}" from "Template"}
  When %Q{I press "Next"}
  When %Q{I select "#{project_name}" from "Select a financial project"}
  When %Q{I select "#{group_name}" from "Select a group to submit"}
  And %Q{I create the order and submit the submission}

  Given %Q{all pending delayed jobs are processed}
end

Given /^all assets for requests in the "([^\"]+)" pipeline have been scanned into the lab$/ do |name|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  pipeline.requests.each { |request| request.asset.container.update_attributes!(:location => pipeline.location) }
end

When /^I check "([^\"]+)" for (\d+) to (\d+)$/ do |label_root, start, finish|
  (start.to_i..finish.to_i).each do |i|
    When %Q{I check "#{label_root} #{i}"}
  end
end

Given /^all of the requests in the "([^\"]+)" pipeline are in the "([^\"]+)" state$/ do |name, state|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  pipeline.requests.each { |request| request.update_attributes!(:state => state) }
end

Then /^the inbox should contain (\d+) requests?$/ do |count|
  with_scope('#pipeline_inbox') do
    if page.respond_to? :should
      page.should have_xpath('//td[contains(@class, "request")]', :count => count.to_i)
    else
      assert page.has_xpath?('//td[contains(@class, "request")]', :count => count.to_i)
    end
  end
end

Then /^the batch (input|output) asset table should be:$/ do |name, expected_table|
  expected_table.diff!(table(tableish("##{name}_assets tr", 'td,th')))
end

Then /^the batch input asset table should have 1 row with (\d+) wells$/ do |count|
  Cucumber::Ast::Table.new([ { 'Wells' => count } ]).diff!(table(tableish("##{name}_assets tr", 'td, th')))
end

Given /^the plate template "([^\"]+)" exists$/ do |name|
  Factory(:plate_template, :name => name)
end

# This is a complete hack to get this to work: it knows where the wells are and goes to get them.  It knows
# where the empty cells are and it goes and gets them too.
When /^I drag (\d+) wells to the scratch pad$/ do |count|
  (1..count.to_i).each do |index|
    sleep(8)        # Apparently we're just too damn fast at some things
    src_well = find("#plate_1 tr:nth-child(#{index}) td[class*='colour']") or raise StandardError, "Could not find the #{index} well in the plate"
    dest_pad = find("#scratch_pad tr:first-child td:first-child")          or raise StandardError, "Could not find the #{index} scratch pad cell"

    src_well.drag_to(dest_pad)
  end
end

#########################################################################################################
# These are the steps for the general checking of the batch request behaviour.  Note that you probably
# shouldn't be merging these steps into generic ones as they are fairly specific.
#########################################################################################################
def build_batch_for(name, count, &block)
  pipeline           = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  submission_details = yield(pipeline)

  user = Factory(:user)

  assets = (1..count.to_i).map do |_|
    asset_attributes = { }
    if submission_details.key?(:holder_type)
      asset_attributes[:container] = Factory(submission_details[:holder_type], :location_id => pipeline.location_id)
    else
      asset_attributes[:location_id] = pipeline.location_id
    end
    Factory(submission_details[:asset_type], asset_attributes)
  end

  # Build a submission that should end up in the appropriate inbox, once all of the assets have been
  # deemed as scanned into the lab!
  LinearSubmission.build!(
    :study    => Factory(:study),
    :project  => Factory(:project),
    :workflow => pipeline.request_types.last.workflow,
    :user     => user,

    # Setup the assets so that they have samples and they are scanned into the correct lab.
    :assets        => assets,
    :request_types => pipeline.request_type_ids,

    # Request parameter options
    :request_options => submission_details[:request_options]
  )
  Given %Q{all pending delayed jobs are processed}

  # Then build a batch that will hold all of these requests, ensuring that it appears to be at least started
  # in some form.
  requests = pipeline.requests.ready_in_storage.all
  raise StandardError, "Pipeline has #{requests.size} requests waiting rather than #{count}" if requests.size != count.to_i
  batch    = Batch.create!(:pipeline => pipeline, :user => user, :requests => requests)
end

def requests_for_pipeline(name, count, &block)
  pipeline          = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  requests_in_inbox = pipeline.requests.ready_in_storage.full_inbox.all

  # There should be requests in the inbox and they should be clones of original requests.
  assert_equal(count.to_i, requests_in_inbox.size, "Unexpected number of requests in the #{name.inspect} inbox")
  yield(requests_in_inbox)
end

# Bad, I know, but it gets the job done for the genotyping pipelines!
Given /^the batch and all its requests are pending$/ do
  batch = Batch.first or raise StandardError, "There appears to be no batches!"
  batch.update_attributes!(:state => 'pending')
  batch.requests.each { |r| r.update_attributes!(:state => 'pending') }
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
      :asset_type => :library_tube,
      :request_options => {
        :fragment_size_required_from => 1,
        :fragment_size_required_to   => 100,
        :read_length                 => pipeline.request_types.last.request_class_name.constantize::Metadata.attribute_details_for(:read_length).to_field_info.selection.first
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
  build_batch_for(name, count.to_i) do |pipeline|
    {
      :asset_type => :sample_tube,
      :request_options => {
        :fragment_size_required_from => 1,
        :fragment_size_required_to   => 100,
        :library_type                => 'Standard'
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
  build_batch_for(name, count.to_i) do |pipeline|
    {
      :asset_type => :well,
      :holder_type => :plate
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
