# frozen_string_literal: true

# rubocop:todo Layout/LineLength
Given /^I have a sample tube "([^"]*)" in study "([^"]*)" in asset group "([^"]*)"$/ do |sample_tube_barcode, study_name, asset_group_name|
  # rubocop:enable Layout/LineLength
  study = Study.find_by(name: study_name)
  sample_tube = FactoryBot.create(:sample_tube, barcode: sample_tube_barcode)
  sample_tube.primary_aliquot.sample.rename_to!("Sample_#{sample_tube_barcode}")
  asset_group = AssetGroup.find_by(name: asset_group_name)
  asset_group = FactoryBot.create(:asset_group, name: asset_group_name, study: study) if asset_group.nil?

  asset_group.assets << sample_tube.receptacle
  asset_group.save!
end

Given /^I have a PacBio submission$/ do
  step('I have a plate for PacBio')
  project = Project.find_by(name: 'Test project')
  study = Study.find_by(name: 'Test study')

  submission_template = SubmissionTemplate.find_by(name: 'PacBio')
  order =
    submission_template.create_with_submission!(
      study: study,
      project: project,
      user: User.last,
      assets: Plate.find_from_barcode('DN1234567').wells.all,
      submission: FactoryBot.build(:submission),
      request_options: {
        :multiplier => {
          '1' => '1',
          '3' => '1'
        },
        'insert_size' => '500',
        'sequencing_type' => 'Standard'
      }
    )
  order.submission.built!
  step('1 pending delayed jobs are processed')
end

Given /^I have a plate for PacBio$/ do
  plate = FactoryBot.create(:plate, well_count: 2, barcode: 1_234_567)
  plate.wells.each do |well|
    sample = FactoryBot.create(:sample, name: "Sample_#{well.map_description}")
    well.aliquots << FactoryBot.create(:untagged_aliquot, sample: sample)
  end
  AssetGroup.create!(name: 'PacBio group', study: Study.find_by(name: 'Test study')).assets << plate.wells
end

Given(/^I have a plate for PacBio in study "([^"]*)"$/) do |study_name|
  plate = FactoryBot.create :plate_with_untagged_wells, sample_count: 1, barcode: '1234567'
  AssetGroup.create!(name: 'PacBio group', study: Study.find_by(name: study_name)).assets << plate.wells
end

Given /^I have a PacBio Library Prep batch$/ do
  step('I have a sample tube "222" in study "Test study" in asset group "Test study group"')
  step('I have a PacBio submission')
  step('I am on the show page for pipeline "PacBio Library Prep"')
  step('I check "Select SQPD-1234567 for batch"')
  step('I press the first "Submit"')
  step('Well "DN1234567":"A1" has a PacBioLibraryTube "NT333U"')
  step('Well "DN1234567":"B1" has a PacBioLibraryTube "NT444D"')
end

Given /^Well "([^"]*)":"([^"]*)" has a PacBioLibraryTube "([^"]*)"$/ do |plate_barcode, well, library_tube_barcode|
  well = Plate.find_from_barcode(plate_barcode).wells.located_at(well).first
  request = Request.find_by(asset_id: well.id)
  tube = request.target_asset.labware
  tube.update!(name: well.display_name)
  tube.primary_barcode.update!(barcode: library_tube_barcode)
end

Given /^I have a fast PacBio sequencing batch$/ do
  step('I have a PacBio submission')
  library_1 = FactoryBot.create :pac_bio_library_tube, smrt_cells_available: 3, barcode: '333'
  library_2 = FactoryBot.create :pac_bio_library_tube, barcode: '444'
  PacBioSequencingRequest.first.update!(asset: library_1)
  PacBioSequencingRequest.last.update!(asset: library_2)
  step('I am on the show page for pipeline "PacBio Sequencing"')
  step('I check "Select Request Group 0"')

  step('I check the invisible "Select Request 0"')
  step('I check the invisible "Select Request 1"')
  step('I press "Submit"')
end

Given /^I have a PacBio sequencing batch$/ do
  step('I have a PacBio Library Prep batch')
  step('I follow "DNA Template Prep Kit Box Barcode"')
  step('I fill in "DNA Template Prep Kit Box Barcode" with "999"')
  step('I press "Next step"')
  step('I press "Next step"')
  step('I select "Pass" from "QC PacBioLibraryTube NT333U"')
  step('I select "Pass" from "QC PacBioLibraryTube NT444D"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('I am on the show page for pipeline "PacBio Sequencing"')
  step('I check "Select Request Group 0"')
  step('I check the invisible "Select Request 0"')
  step('I check the invisible "Select Request 1"')
  step('I press the first "Submit"')
end

Given /^the sample tubes are part of the study$/ do
  sample_tube = SampleTube.find_from_barcode('NT111')
  sample_tube.primary_aliquot.sample.sample_metadata.update!(sample_common_name: 'Homo Sapien', sample_taxon_id: 9606)
  Study.find_by(name: 'Test study').samples << sample_tube.primary_aliquot.sample

  sample_tube = SampleTube.find_from_barcode('NT222')
  sample_tube.primary_aliquot.sample.sample_metadata.update!(
    sample_common_name: 'Flu',
    sample_taxon_id: 123,
    sample_strain_att: 'H1N1'
  )
  Study.find_by(name: 'Test study').samples << sample_tube.primary_aliquot.sample
end

Given /^sample tube "([^"]*)" is part of study "([^"]*)"$/ do |barcode, study_name|
  sample_tube = SampleTube.find_from_barcode("NT#{barcode}")
  Study.find_by(name: study_name).samples << sample_tube.primary_aliquot.sample
end

Then /^(\d+) PacBioSequencingRequests for "([^"]*)" should be "([^"]*)"$/ do |number_of_requests, asset_barcode, state|
  library_tube = PacBioLibraryTube.find_from_barcode(asset_barcode)
  assert_equal number_of_requests.to_i,
               PacBioSequencingRequest.where(asset_id: library_tube.receptacle.id, state: state).count
end

Then /^the PacBioSamplePrepRequests for "([^"]*)" should be "([^"]*)"$/ do |asset_barcode, state|
  plate_barcode, location = asset_barcode.split(':')
  well = Plate.find_from_barcode(plate_barcode).wells.located_at(location).first
  assert_equal 1, PacBioSamplePrepRequest.where(asset_id: well.id, state: state).count
end

Then /^the PacBio manifest for the last batch should look like:$/ do |expected_results_table|
  pac_bio_run_file = PacBio::SampleSheet.new.create_csv_from_batch(Batch.last)
  csv_rows = pac_bio_run_file.split("\r\n")
  csv_rows.shift(8)
  expected_results_table.column_names.each { |c| expected_results_table.map_column!(c, &:presence) }
  actual_table = CSV.parse(csv_rows.map { |c| "#{c}\r\n" }.join(''))
  expected_results_table.diff!(actual_table)
end

Given /^the UUID for well "([^"]*)" on plate "([^"]*)" is "([^"]*)"$/ do |well_position, plate_barcode, uuid|
  plate = Plate.find_from_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  step("the UUID for the well with ID #{well.id} is \"#{uuid}\"")
end

Given /^the UUID for Library "([^"]*)" is "([^"]*)"$/ do |barcode, uuid|
  step("the UUID for the receptacle with ID #{Labware.find_by_barcode(barcode).receptacle.id} is \"#{uuid}\"")
end

Then /^the PacBio sample prep worksheet should look like:$/ do |expected_results_table|
  worksheet = page.source
  csv_rows = worksheet.split("\r\n")
  csv_rows.shift(2)
  actual_table = CSV.parse(csv_rows.map { |c| "#{c}\r\n" }.join(''))
  expected_results_table.diff!(actual_table)
end

Then /^the PacBioLibraryTube "(.*?)" should have (\d+) SMRTcells$/ do |barcode, cells|
  assert_equal PacBioLibraryTube.find_from_barcode(barcode).pac_bio_library_tube_metadata.smrt_cells_available || 0,
               cells.to_i
end

Given /^the reference genome "([^"]*)" exists$/ do |name|
  FactoryBot.create :reference_genome, name: name
end

Then /^the sample reference sequence table should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#reference_sequence')))
end

Given /^the study "([^"]*)" has a reference genome of "([^"]*)"$/ do |study_name, reference_genome_name|
  Study
    .find_by(name: study_name)
    .study_metadata
    .update!(reference_genome: ReferenceGenome.find_by(name: reference_genome_name))
end

Then /^the PacBio manifest should be:$/ do |expected_results_table|
  pac_bio_run_file = page.source
  csv_rows = pac_bio_run_file.split("\r\n")
  csv_rows.shift(8)
  actual_table = CSV.parse(csv_rows.map { |c| "#{c}\r\n" }.join(''))
  expected_results_table.column_names.each { |c| expected_results_table.map_column!(c, &:presence) }
  expected_results_table.diff!(actual_table)
end

Then /^I fill in the field for "(.*?)" with "(.*?)"$/ do |asset_name, content|
  request_id = Labware.find_by!(name: asset_name).requests_as_source.ids.first
  step("I fill in the hidden field \"locations_for_#{request_id}\" with \"#{content}\"")
end

When /^I drag the library tube to well "(.*?)"$/ do |well|
  step "I drag \".library_tube\" to \"#well_#{well}\""
end
