Given /^I have a pipeline called "([^\"]*)"$/ do |name|
  request_type = Factory :request_type
  pipeline = Factory :pipeline, :name => name, :request_types => [request_type]
  pipeline.workflow.update_attributes!(:item_limit => 8)
  task = Factory :task, :name => "Task1", :workflow => pipeline.workflow
end

Given /^I have a batch in "([^\"]*)"$/ do |pipeline|
  When  %Q{I have a "pending" batch in "#{pipeline}"}
end

Given /^I have a "([^\"]*)" batch in "([^\"]*)"$/ do |state, pipeline|
  @batch = Factory :batch, :pipeline => Pipeline.find_by_name(pipeline), :state => state, :production_state => nil
end

Given /^I have a control called "([^\"]*)" for "([^\"]*)"$/ do |name, pipeline_name|
  control = Factory :control, :name => name, :pipeline => Pipeline.find_by_name(pipeline_name)
end

def pipeline_name_to_asset_type(pipeline_name)
  pipeline_name.include?('Library Preparation') || pipeline_name.include?('Library preparation') ? :sample_tube : :library_tube
end

def create_request_for_pipeline(pipeline_name, options = {})
  pipeline = Pipeline.find_by_name(pipeline_name) or raise StandardError, "Cannot find pipeline #{pipeline_name.inspect}"
  request_metadata_attributes = { :read_length => 76, :fragment_size_required_from => 100, :fragment_size_required_to => 200, :library_type => 'Standard' }
  Factory(:request, options.merge(:request_type => pipeline.request_types.last, :asset => Factory(pipeline_name_to_asset_type(pipeline_name)), :request_metadata_attributes => request_metadata_attributes)).tap do |request|
    request.asset.update_attributes!(:location => pipeline.location)
  end
end

Given /^I have a request for "([^\"]*)"$/ do |pipeline_name|
  create_request_for_pipeline(pipeline_name)
end

Given /^I have (\d+) requests for "([^"]*)" that are part of the same submission$/ do |count, pipeline_name|
  pipeline   = Pipeline.find_by_name(pipeline_name) or raise StandardError, "Cannot find pipeline #{pipeline_name.inspect}"
  submission = Factory(:submission, :request_types => [ pipeline.request_types.last.id ])
  (1..count.to_i).each do |_|
    create_request_for_pipeline(pipeline_name, :submission => submission)
  end
end

Given /^all requests are in the "([^"]*)" state$/ do |state|
  Request.update_all("state=#{state.inspect}")
end

Given /^all requests for the submission with UUID "([^\"]+)" are in the "([^\"]+)" state$/ do |uuid, state|
  submission = Uuid.lookup_single_uuid(uuid).resource
  Request.update_all("state=#{state.inspect}", [ 'submission_id=?', submission.id ])
end

Given /^I on batch page$/ do
  visit "/batches/#{Batch.last.id}"
end

Given /^I am viewing the pipeline page$/ do
  visit "/pipelines/#{Pipeline.last.id}"
end

Given /^I have data loaded from SNP$/ do


end
When /^I check request "(\d+)" for pipeline "([^"]+)"/ do |request_number, pipeline_name|
  #TODO find the request checkboxes in the current page (by name "request_... ") so we don't need
  # do give the pipelin name
  request_number = request_number.to_i
  pipeline = Pipeline.find_by_name(pipeline_name)

  request = pipeline.requests.inbox[request_number-1]
  check("request_#{request.id}")
end

Then /^the requests from "([^\"]+)" batches should not be in the inbox$/ do |name|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  raise StandardError, "There are no batches in #{name.inspect}" if pipeline.batches.empty?
  pipeline.batches.each do |batch|
    batch.requests.each do |request|
      assert page.has_no_xpath?("//*[@id='request_#{request.id}']")
    end
  end
end

When /^I check request_group "(\d+)" for pipeline "([^"]+)"/ do |request_number, pipeline_name|
  #TODO find the request checkboxes in the current page (by name "request_... ") so we don't need
  # do give the pipelin name
  request_number = request_number.to_i
  pipeline = Pipeline.find_by_name(pipeline_name)

  request_group = pipeline.get_input_request_groups.to_a[request_number-1].first
  check("request_group_#{request_group.join(", ").gsub(/[^a-z0-9]+/, '_')}")

end
Given /^I have a freezer called "([^\"]*)"$/ do |location_name|
  Factory :location, :name => location_name
end

When /^I fill in the plate barcode$/ do
  When %Q{I fill in "barcode_0" with "#{Plate.last.ean13_barcode}"}
#  puts "Plate #{Plate.last.id} -- #{Plate.last.location_id}"
end

When /^pipeline debug$/ do
  puts "Plate #{Plate.last.id} -- #{Plate.last.location_id}"
  puts "Plate #{Plate.last.id} -- #{Plate.last.container}"
  puts Pipeline.find_by_name("DNA QC").location_id
  puts Pipeline.find_by_name("DNA QC").requests.ready_in_storage.pipeline_pending.size
  save_and_open_page
  debugger
end

Then /^I have added some output plates$/ do
  batch = Batch.last
  well = Factory :well
  Factory :map, :description => "A1"
  well_request = Factory :request, :target_asset => well
  plate = Factory :plate
  plate.add_well_by_map_description(well, "A1")
  batch.requests << well_request
  batch.save
end

Given /^Microarray genotyping is set up$/ do
  # Submission and request types
  submission_workflow = Factory :submission_workflow, :key => "microarray_genotyping", :name => "Microarray genotyping"
  dna_qc = Factory :request_type, :key => "dna_qc", :name => "DNA QC", :workflow => submission_workflow, :order => 1, :asset_type => "Well", :initial_state => "pending"
  cherrypick = Factory :request_type, :key => "cherrypick", :name => "Cherrypick", :workflow => submission_workflow, :order => 2, :initial_state => "blocked", :asset_type => "Well"
  genotyping = Factory :request_type, :key => "genotyping", :name => "Genotyping", :workflow => submission_workflow, :order => 3, :asset_type => "Well"

  # Workflows and tasks
  cherrypick_pipeline = Factory :pipeline, :name => "Cherrypick", :request_type_id => cherrypick.id, :group_by_parent => true, :location_id => Location.find_by_name("Sample logistics freezer").id
  dna_qc_pipeline = Factory :pipeline, :name => "DNA QC", :request_type_id => dna_qc.id, :group_by_parent => true, :location_id => Location.find_by_name("Sample logistics freezer").id, :next_pipeline_id => cherrypick_pipeline.id

  dna_qc_workflow = Factory :lab_workflow, :name => "DNA QC", :pipeline => dna_qc_pipeline
  Factory :task, :name => "Duplicate Samples Check", :sti_type => "DuplicateSamplesCheckTask", :sorted => 0, :workflow => dna_qc_workflow, :batched => 0
  Factory :task, :name => "QC result", :sti_type => "DnaQcTask", :sorted => 1, :workflow => dna_qc_workflow, :batched => 1

  cherrypick_workflow = Factory :lab_workflow, :name => "Cherrypick", :pipeline => cherrypick_pipeline
  Factory :task, :name => "Filter Samples", :sti_type => "FilterSamplesTask", :sorted => 0, :workflow => cherrypick_workflow
  Factory :task, :name => "Select Plate Template", :sti_type => "PlateTemplateTask", :sorted => 1, :workflow => cherrypick_workflow
  Factory :task, :name => "Approve Plate Layout", :sti_type => "CherrypickTask", :sorted => 2, :workflow => cherrypick_workflow
  Factory :task, :name => "Assign a Purpose for Output Plates", :sti_type => "AssignPlatePurposeTask", :sorted => 3, :workflow => cherrypick_workflow
  Factory :plate_purpose, :name => "Frag"
  Factory :task, :name => "Set Location", :sti_type => "SetLocationTask", :sorted => 4, :workflow => cherrypick_workflow
#  Factory :task, :name => "Export Plate to SNP", :sti_type => "ExportPlateTask", :sorted => 4, :workflow => cherrypick_workflow

  #Registering submissin template
  submission = LinearSubmission.new
  submission.request_type_ids = [dna_qc, cherrypick, genotyping].map { |rt| rt.id }
  submission.info_differential = submission_workflow.id
  # TODO[xxx]: need to setup the field_infos on the submission based on the properties.
  # submission.set_field_infos([ FieldInfo.new(....) .... ])
  SubmissionTemplate.new_from_submission(submission_workflow.name, submission).save!
end

Then /^the pipeline inbox should be:$/ do |expected_results_table|
   expected_results_table.diff!(table(tableish('table#pipeline_inbox tr', 'td,th')))
end

When /^I click on the last "([^\"]*)" batch$/ do |status|
  batch = Batch.last(:conditions => { :state => status })
  When %Q{I follow "#{status} batch #{batch.id}"}
end

Given /^the maximum batch size for the pipeline "([^\"]+)" is (\d+)$/ do |name, max_size|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  pipeline.update_attributes!(:max_size => max_size.to_i)
end

Given /^the pipeline "([^\"]+)" accepts "([^\"]+)" requests$/ do |pipeline_name, request_name|
  pipeline     = Pipeline.find_by_name(pipeline_name) or raise StandardError, "Cannot find pipeline #{pipeline_name.inspect}"
  request_type = RequestType.find_by_name(request_name) or raise StandardError, "Cannot find request type #{request_name.inspect}"
  pipeline.update_attributes!(:request_types => [request_type])
end

Given /^the last request is in the "([^\"]+)" state$/ do |state|
  Request.last.update_attributes!(:state => state)
end
