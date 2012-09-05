Given /^I have a sample tube "([^"]*)" in study "([^"]*)" in asset group "([^"]*)"$/ do |sample_tube_barcode, study_name, asset_group_name|
  study = Study.find_by_name(study_name)
  sample_tube = Factory(:sample_tube, :barcode => sample_tube_barcode, :location =>  Location.find_by_name('PacBio sample prep freezer'))
  sample_tube.primary_aliquot.sample.rename_to!("Sample_#{sample_tube_barcode}")
  asset_group = AssetGroup.find_by_name(asset_group_name)
  if asset_group.nil?
    asset_group = Factory(:asset_group, :name => asset_group_name, :study => study)
  end

  asset_group.assets << sample_tube
  asset_group.save!
end

Given /^I have a PacBio submission$/ do
  project = Project.find_by_name("Test project")
  study = Study.find_by_name("Test study")

  submission_template = SubmissionTemplate.find_by_name('PacBio')
  submission = submission_template.create_and_build_submission!(
    :study => study,
    :project => project,
    :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
    :user => User.last,
    :assets => SampleTube.all,
    :request_options => {"multiplier"=>{"1"=>"1", "3"=>"1"}, "insert_size"=>"250", "sequencing_type"=>"Standard"}
    )
  And %Q{1 pending delayed jobs are processed}
end


Then /^I should have (\d+) PacBioSequencingRequests$/ do |number_of_requests|
  assert_equal number_of_requests.to_i, PacBioSequencingRequest.count
end

Given /^I have a PacBio Sample Prep batch$/ do
  Given %Q{I have a sample tube "222" in study "Test study" in asset group "Test study group"}
  Given %Q{I have a PacBio submission}
  Given %Q{I am on the show page for pipeline "PacBio Sample Prep"}
  When %Q{I check "Select SampleTube 111 for batch"}
  When %Q{I check "Select SampleTube 222 for batch"}
  When %Q{I press "Submit"}
  Given %Q{SampleTube "111" has a PacBioLibraryTube "333"}
  Given %Q{SampleTube "222" has a PacBioLibraryTube "444"}
end

Given /^SampleTube "([^"]*)" has a PacBioLibraryTube "([^"]*)"$/ do |sample_tube_barcode, library_tube_barcode|
  sample_tube = SampleTube.find_by_barcode(sample_tube_barcode)
  request = Request.find_by_asset_id(sample_tube.id)
  request.target_asset.update_attributes!(:barcode => library_tube_barcode)
end

Given /^I have a fast PacBio sequencing batch$/ do
  Given %Q{I have a sample tube "222" in study "Test study" in asset group "Test study group"}
  Given %Q{the sample tubes are part of the study}
  Given %Q{I have a PacBio submission}
  location = Location.find_by_name("PacBio sequencing freezer")
  library_1 = PacBioLibraryTube.create!(:location => location, :barcode => "333", :aliquots => SampleTube.find_by_barcode(111).aliquots.map(&:clone))
  library_1.pac_bio_library_tube_metadata.update_attributes!(:prep_kit_barcode => "999", :smrt_cells_available => 3)
  library_2 = PacBioLibraryTube.create!(:location => location, :barcode => "444", :aliquots => SampleTube.find_by_barcode(222).aliquots.map(&:clone))
  library_2.pac_bio_library_tube_metadata.update_attributes!(:prep_kit_barcode => "999", :smrt_cells_available => 1)
  PacBioSequencingRequest.first.update_attributes!(:asset => library_1)
  PacBioSequencingRequest.last.update_attributes!(:asset => library_2)
  Given %Q{I am on the show page for pipeline "PacBio Sequencing"}
  When %Q{I check "Select Request Group 0"}
  And %Q{I check "Select Request 0"}
  And %Q{I check "Select Request 1"}
  And %Q{I press "Submit"}
end

Given /^I have a PacBio sequencing batch$/ do
  Given %Q{I have a PacBio Sample Prep batch}
  When %Q{I follow "Start batch"}
  When %Q{I fill in "DNA Template Prep Kit Box Barcode" with "999"}
  And %Q{I press "Next step"}
  When %Q{I select "Pass" from "QC PacBioLibraryTube 333"}
  And %Q{I select "Pass" from "QC PacBioLibraryTube 444"}
  And %Q{I press "Next step"}
  When %Q{I fill in "Number of SMRTcells for PacBioLibraryTube 333" with "3"}
  And %Q{I fill in "Number of SMRTcells for PacBioLibraryTube 444" with "1"}
  And %Q{I press "Next step"}
  When %Q{I press "Release this batch"}
  When %Q{set the location of PacBioLibraryTube "3980000333858" to be in "PacBio sequencing freezer"}
  When %Q{set the location of PacBioLibraryTube "3980000444684" to be in "PacBio sequencing freezer"}
  Given %Q{I am on the show page for pipeline "PacBio Sequencing"}
  When %Q{I check "Select Request Group 0"}
  And %Q{I check "Select Request 0"}
  And %Q{I check "Select Request 1"}
  And %Q{I press "Submit"}
  Given %Q{the sample tubes are part of the study}
end

Given /^the sample tubes are part of the study$/ do
  sample_tube = SampleTube.find_by_barcode(111)
  sample_tube.primary_aliquot.sample.sample_metadata.update_attributes!(:sample_common_name => "Homo Sapien", :sample_taxon_id => 9606)
  Study.find_by_name('Test study').samples << sample_tube.primary_aliquot.sample

  sample_tube = SampleTube.find_by_barcode(222)
  sample_tube.primary_aliquot.sample.sample_metadata.update_attributes!(:sample_common_name => "Flu", :sample_taxon_id => 123, :sample_strain_att => "H1N1")
  Study.find_by_name('Test study').samples << sample_tube.primary_aliquot.sample
end

Given /^sample tube "([^"]*)" is part of study "([^"]*)"$/ do |barcode, study_name|
  sample_tube = SampleTube.find_by_barcode(barcode)
  Study.find_by_name(study_name).samples << sample_tube.primary_aliquot.sample
end

When /^set the location of PacBioLibraryTube "([^"]*)" to be in "([^"]*)"$/ do |barcode,freezer|
  Asset.find_from_machine_barcode(barcode).update_attributes!(:location => Location.find_by_name(freezer))
end

Then /^(\d+) PacBioSequencingRequests for "([^"]*)" should be "([^"]*)"$/ do |number_of_requests, asset_barcode, state|
  library_tube = PacBioLibraryTube.find_by_barcode(asset_barcode)
  assert_equal number_of_requests.to_i, PacBioSequencingRequest.find_all_by_asset_id_and_state(library_tube.id,state).count
end

Then /^the PacBioSamplePrepRequests for "([^"]*)" should be "([^"]*)"$/ do |asset_barcode, state|
  sample_tube = SampleTube.find_by_barcode(asset_barcode)
  assert_equal 1, PacBioSamplePrepRequest.find_all_by_asset_id_and_state(sample_tube.id,state).count
end

Then /^the plate layout should look like:$/ do |expected_results_table|
  actual_table = table(tableish('table.plate tr', 'option[@selected],th.plate_column'))
  expected_results_table.diff!(actual_table)
end

Then /^the PacBio manifest for the last batch should look like:$/ do |expected_results_table|
  pac_bio_run_file = PacBio::SampleSheet.new.create_csv_from_batch(Batch.last)
  csv_rows = pac_bio_run_file.split(/\r\n/)
  csv_rows.shift(8)
  actual_table = FasterCSV.parse( csv_rows.map{|c| "#{c}\r\n"}.join(''))
  expected_results_table.diff!(actual_table)
end

Given /^the UUID for well "([^"]*)" on plate "([^"]*)" is "([^"]*)"$/ do |well_position, plate_barcode, uuid|
  plate = Plate.find_by_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  Given %Q{the UUID for the well with ID #{well.id} is "#{uuid}"}
end

Given /^the UUID for Library "([^"]*)" is "([^"]*)"$/ do |barcode,uuid|
  Given %Q{the UUID for the asset with ID #{Asset.find_by_barcode(barcode).id} is "#{uuid}"}
end

Given /^the sample validation webservice returns "(true|false)"$/ do |success_boolean|
  if success_boolean == 'true'
    FakeSampleValidationService.instance.return_value(true)
  else
    FakeSampleValidationService.instance.return_value(false)
  end
end

Then /^the PacBio sample prep worksheet should look like:$/ do |expected_results_table|
  worksheet = page.body
  csv_rows = worksheet.split(/\r\n/)
  csv_rows.shift(2)
  actual_table = FasterCSV.parse( csv_rows.map{|c| "#{c}\r\n"}.join(''))
  expected_results_table.diff!(actual_table)
end

Given /^I have progressed to the Reference Sequence task$/ do
  Given %Q{I have a PacBio sequencing batch}
  When %Q{I follow "Start batch"}
  When %Q{I fill in "Binding Kit Box Barcode" with "777"}
  And %Q{I press "Next step"}
  When %Q{I fill in "Movie length for 333" with "12"}
  And %Q{I fill in "Movie length for 444" with "23"}
  And %Q{I press "Next step"}
end

Given /^the reference genome "([^"]*)" exists$/ do |name|
  Factory :reference_genome, :name =>name
end

Given /^the sample in tube "([^"]*)" has a reference genome of "([^"]*)"$/ do |barcode, reference_genome_name|
  sample_tube = SampleTube.find_by_barcode(barcode)
  sample_tube.primary_aliquot.sample.sample_metadata.update_attributes!(:reference_genome => ReferenceGenome.find_by_name(reference_genome_name))
end

Then /^the sample reference sequence table should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#reference_sequence tr', 'td,th')))
end

Then /^Library tube "([^"]*)" should have protocol "([^"]*)"$/ do |barcode, expected_protocol|
  assert_equal expected_protocol, PacBioLibraryTube.find_by_barcode(barcode).pac_bio_library_tube_metadata.protocol
end

Given /^the study "([^"]*)" has a reference genome of "([^"]*)"$/ do |study_name, reference_genome_name|
  Study.find_by_name(study_name).study_metadata.update_attributes!(:reference_genome => ReferenceGenome.find_by_name(reference_genome_name))
end

Then /^the default protocols should be:$/ do |expected_results_table|
    actual_table = table(tableish('table#reference_sequence tr', 'option[@selected],th#protocol'))
end

Then /^the PacBio manifest should be:$/ do |expected_results_table|
  pac_bio_run_file = page.body
  csv_rows = pac_bio_run_file.split(/\r\n/)
  csv_rows.shift(8)
  actual_table = FasterCSV.parse( csv_rows.map{|c| "#{c}\r\n"}.join(''))
  expected_results_table.diff!(actual_table)
end
