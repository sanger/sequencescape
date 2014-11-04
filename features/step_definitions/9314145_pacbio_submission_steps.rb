Given /^I have a sample tube "([^"]*)" in study "([^"]*)" in asset group "([^"]*)"$/ do |sample_tube_barcode, study_name, asset_group_name|
  study = Study.find_by_name(study_name)
  sample_tube = Factory(:sample_tube, :barcode => sample_tube_barcode, :location =>  Location.find_by_name('PacBio library prep freezer'))
  sample_tube.primary_aliquot.sample.rename_to!("Sample_#{sample_tube_barcode}")
  asset_group = AssetGroup.find_by_name(asset_group_name)
  if asset_group.nil?
    asset_group = Factory(:asset_group, :name => asset_group_name, :study => study)
  end

  asset_group.assets << sample_tube
  asset_group.save!
end

Given /^I have a PacBio submission$/ do
  step(%Q{I have a plate for PacBio})
  project = Project.find_by_name("Test project")
  study = Study.find_by_name("Test study")

  submission_template = SubmissionTemplate.find_by_name('PacBio')
  submission = submission_template.create_and_build_submission!(
    :study => study,
    :project => project,
    :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
    :user => User.last,
    :assets => Plate.find_by_barcode(1234567).wells.all,
    :request_options => {:multiplier=>{"1"=>"1", "3"=>"1"}, "insert_size"=>"500", "sequencing_type"=>"Standard"}
    )
  step(%Q{1 pending delayed jobs are processed})
end


Then /^I should have (\d+) PacBioSequencingRequests$/ do |number_of_requests|
  assert_equal number_of_requests.to_i, PacBioSequencingRequest.count
end

Given /^I have a plate for PacBio$/ do
  PlatePurpose.stock_plate_purpose.create!(:without_wells, :barcode=>1234567) do |plate|
    plate.wells.create!(:map=>Map.find_by_asset_size_and_description(96,'A1'),:aliquots => SampleTube.find_by_barcode(111).aliquots.map(&:clone))
    plate.wells.create!(:map=>Map.find_by_asset_size_and_description(96,'B1'),:aliquots => SampleTube.find_by_barcode(222).aliquots.map(&:clone)) if  SampleTube.find_by_barcode(222).present?
    plate.location = Location.find_by_name('PacBio library prep freezer')
    AssetGroup.create!(:name=>"PacBio group", :study=>Study.find_by_name('Test study')).assets << plate.wells
  end
end

Given /^I have a PacBio Library Prep batch$/ do
  step(%Q{I have a sample tube "222" in study "Test study" in asset group "Test study group"})
  step(%Q{I have a PacBio submission})
  step(%Q{I am on the show page for pipeline "PacBio Library Prep"})
  step(%Q{I check "Select DN1234567T for batch"})
  step(%Q{I press "Submit"})
  step(%Q{Well "1234567":"A1" has a PacBioLibraryTube "333"})
  step(%Q{Well "1234567":"B1" has a PacBioLibraryTube "444"})
end

Given /^SampleTube "([^"]*)" has a PacBioLibraryTube "([^"]*)"$/ do |sample_tube_barcode, library_tube_barcode|
  sample_tube = SampleTube.find_by_barcode(sample_tube_barcode)
  request = Request.find_by_asset_id(sample_tube.id)
  request.target_asset.update_attributes!(:barcode => library_tube_barcode)
end

Given /^Well "([^"]*)":"([^"]*)" has a PacBioLibraryTube "([^"]*)"$/ do |plate_barcode, well, library_tube_barcode|
  well = Plate.find_by_barcode(plate_barcode).wells.located_at(well).first
  request = Request.find_by_asset_id(well.id)
  request.target_asset.update_attributes!(:barcode => library_tube_barcode, :name=>well.display_name)
end

Given /^I have a fast PacBio sequencing batch$/ do
  step(%Q{I have a sample tube "111" in study "Test study" in asset group "Test study group"})
  step(%Q{I have a sample tube "222" in study "Test study" in asset group "Test study group"})
  step(%Q{the sample tubes are part of the study})
  step(%Q{I have a PacBio submission})
  location = Location.find_by_name("PacBio sequencing freezer")
  library_1 = PacBioLibraryTube.create!(:location => location, :barcode => "333", :aliquots => SampleTube.find_by_barcode(111).aliquots.map(&:clone))
  library_1.pac_bio_library_tube_metadata.update_attributes!(:prep_kit_barcode => "999", :smrt_cells_available => 3)
  library_2 = PacBioLibraryTube.create!(:location => location, :barcode => "444", :aliquots => SampleTube.find_by_barcode(222).aliquots.map(&:clone))
  library_2.pac_bio_library_tube_metadata.update_attributes!(:prep_kit_barcode => "999", :smrt_cells_available => 1)
  PacBioSequencingRequest.first.update_attributes!(:asset => library_1)
  PacBioSequencingRequest.last.update_attributes!(:asset => library_2)
  step(%Q{I am on the show page for pipeline "PacBio Sequencing"})
  step(%Q{I check "Select Request Group 0"})
  step(%Q{I check "Select Request 0"})
  step(%Q{I check "Select Request 1"})
  step(%Q{I press "Submit"})
end

Given /^I have a PacBio sequencing batch$/ do
  step(%Q{I have a PacBio Library Prep batch})
  step(%Q{I follow "DNA Template Prep Kit Box Barcode"})
  step(%Q{I fill in "DNA Template Prep Kit Box Barcode" with "999"})
  step(%Q{I press "Next step"})
  step(%Q{I press "Next step"})
  step(%Q{I select "Pass" from "QC PacBioLibraryTube 333"})
  step(%Q{I select "Pass" from "QC PacBioLibraryTube 444"})
  step(%Q{I press "Next step"})
  step(%Q{I press "Release this batch"})
  step(%Q{set the location of PacBioLibraryTube "3980000333858" to be in "PacBio sequencing freezer"})
  step(%Q{set the location of PacBioLibraryTube "3980000444684" to be in "PacBio sequencing freezer"})
  step(%Q{I am on the show page for pipeline "PacBio Sequencing"})
  step(%Q{I check "Select Request Group 0"})
  step(%Q{I check "Select Request 0"})
  step(%Q{I check "Select Request 1"})
  step(%Q{I press "Submit"})
  step(%Q{the sample tubes are part of the study})
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
  plate_barcode, location = asset_barcode.split(':')
  well = Plate.find_by_barcode(plate_barcode.gsub(/[A-Z]/,'')).wells.located_at(location).first
  assert_equal 1, PacBioSamplePrepRequest.find_all_by_asset_id_and_state(well.id,state).count
end

Then /^the plate layout should look like:$/ do |expected_results_table|
  actual_table = table(tableish('table.plate tr', 'option[@selected],th.plate_column'))
  expected_results_table.diff!(actual_table)
end

Then /^the PacBio manifest for the last batch should look like:$/ do |expected_results_table|
  pac_bio_run_file = PacBio::SampleSheet.new.create_csv_from_batch(Batch.last)
  csv_rows = pac_bio_run_file.split(/\r\n/)
  csv_rows.shift(8)
  expected_results_table.column_names.each {|c| expected_results_table.map_column!(c) {|d| d.blank? ? nil : d }}
  actual_table = FasterCSV.parse( csv_rows.map{|c| "#{c}\r\n"}.join(''))
  expected_results_table.diff!(actual_table)
end

Given /^the UUID for well "([^"]*)" on plate "([^"]*)" is "([^"]*)"$/ do |well_position, plate_barcode, uuid|
  plate = Plate.find_by_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  step(%Q{the UUID for the well with ID #{well.id} is "#{uuid}"})
end

Given /^the UUID for Library "([^"]*)" is "([^"]*)"$/ do |barcode,uuid|
  step(%Q{the UUID for the asset with ID #{Asset.find_by_barcode(barcode).id} is "#{uuid}"})
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
  step(%Q{I have a PacBio sequencing batch})
  step(%Q{I follow "Binding Kit Box Barcode"})
  step(%Q{I fill in "Binding Kit Box Barcode" with "777"})
  step(%Q{I press "Next step"})
  step(%Q{I select "30" from "Movie length for 333"})
  step(%Q{I select "60" from "Movie length for 444"})
  step(%Q{I press "Next step"})
end

Then /^the PacBioLibraryTube "(.*?)" should have (\d+) SMRTcells$/ do |barcode, cells|
  assert_equal PacBioLibraryTube.find_by_barcode(barcode).pac_bio_library_tube_metadata.smrt_cells_available||0, cells.to_i
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
  expected_results_table.column_names.each {|c| expected_results_table.map_column!(c) {|d| d.blank? ? nil : d }}
  expected_results_table.diff!(actual_table)
end
