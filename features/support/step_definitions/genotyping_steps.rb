# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Then /^I should see dna qc table:$/ do |expected_results_table|
  actual_table = table(fetch_table('table#sortable_batches'))
  actual_table.map_column!('Qc') { |_text| '' }
  expected_results_table.diff!(actual_table)
end

When /^I select "([^"]*)" for the first row of the plate$/ do |qc_result|
  1.upto(12) do |i|
    step(%Q{I select "#{qc_result}" from "Plate 1234567 QC status A#{i}"})
  end
end

When /^I select "([^"]*)" for the remaining rows of the plate$/ do |qc_result|
  1.upto(12) do |i|
    ('B'..'H').each do |r|
      step(%Q{I select "#{qc_result}" from "Plate 1234567 QC status #{r}#{i}"})
    end
  end
end

Given /^a plate template exists$/ do
  FactoryGirl.create :plate_template
end

Given /^a robot exists$/ do
  robot = FactoryGirl.create :robot
  robot.robot_properties.create(key: 'max_plates', value: '21')
end

Then /^the manifest for study "([^"]*)" with plate "([^"]*)" should be:$/ do |study_name, plate_barcode, expected_results_table|
  study = Study.find_by(name: study_name)
  plate = Plate.find_by(barcode: plate_barcode)
  manifest = CSV.parse(ManifestGenerator.generate_manifest_for_plate_ids([plate.id], study))
  manifest.shift(3)
  expected_results_table.diff!(manifest)
end

Given(/^I have a plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/) do |plate_barcode, study_name, number_of_samples, asset_group_name|
  purpose = FactoryGirl.create :plate_purpose
  purpose_name = purpose.name
  step(%Q{I have a "#{purpose_name}" plate "#{plate_barcode}" in study "#{study_name}" with #{number_of_samples} samples in asset group "#{asset_group_name}"})
end

Given(/^I have a "([^"]*)" plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/) do |purpose_name, plate_barcode, study_name, number_of_samples, asset_group_name|
  study = Study.find_by(name: study_name)
  purpose = Purpose.find_by(name: purpose_name)
  plate = FactoryGirl.create(:plate, purpose: purpose, barcode: plate_barcode, location: Location.find_by(name: 'Sample logistics freezer'))

  asset_group = study.asset_groups.find_by(name: asset_group_name) || study.asset_groups.create!(name: asset_group_name)
  asset_group.assets << (1..number_of_samples.to_i).map do |index|
    FactoryGirl.create(:well, plate: plate, map_id: index).tap do |well|
      well.aliquots.create!(sample: FactoryGirl.create(:sample, name: "Sample_#{plate_barcode}_#{index}"),
                            study: study)
    end
  end
end

Given(/^plate "([^"]*)" in study "([^"]*)" is in asset group "([^"]*)"$/) do |plate_barcode, study_name, asset_group_name|
  study = Study.find_by(name: study_name)
  plate = Plate.find_by(barcode: plate_barcode)
  asset_group = AssetGroup.find_or_create_by(name: asset_group_name, study_id: study.id)
  plate.wells.each do |well|
    asset_group.assets << well
  end
  asset_group.save!
end

Given /^I have a cherrypicking batch$/ do
  step('I have a cherrypicking batch with 96 samples')
end

Given(/^I have a cherrypicking batch with (\d+) samples$/) do |number_of_samples|
  step('I am a "administrator" user logged in as "user"')
  step('I have a project called "Test project"')
  step('I have an active study called "Test study"')
  step(%Q{I have a plate "1234567" in study "Test study" with #{number_of_samples} samples in asset group "Plate asset group"})

  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')

  step('I check "Select DN1234567T for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')
end

Given(/^a robot exists with barcode "([^"]*)"$/) do |robot_barcode|
  robot = FactoryGirl.create :robot, barcode: robot_barcode
  robot.robot_properties.create(key: 'max_plates', value: '21')
  robot.robot_properties.create(key: 'SCRC1', value: '1')
  robot.robot_properties.create(key: 'SCRC2', value: '2')
  robot.robot_properties.create(key: 'SCRC3', value: '3')
  robot.robot_properties.create(key: 'DEST1', value: '20')
end

When(/^I complete the cherrypicking batch with "([^"]*)" plate purpose but dont release it$/) do |plate_purpose_name|
  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step(%Q{I select "#{plate_purpose_name}" from "Output plate purpose"})
  step('I press "Next step"')
  step('I press "Next step"')
  step('I select "Genotyping freezer" from "Location"')
  step('I press "Next step"')
end

When /^I complete the cherrypicking batch with "([^"]*)" plate purpose$/ do |plate_purpose_name|
  step(%Q{I complete the cherrypicking batch with "#{plate_purpose_name}" plate purpose but dont release it})
  step('I press "Release this batch"')
  step 'I should see "Batch released"'
end

Given /^I have a cherrypicked plate with barcode "([^"]*)" and plate purpose "([^"]*)"$/ do |plate_barcode, plate_purpose_name|
  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')
  step('I check "Select DN1234567T for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')
  step(%Q{a plate barcode webservice is available and returns "#{plate_barcode}"})
  step(%Q{I complete the cherrypicking batch with "#{plate_purpose_name}" plate purpose but dont release it})
end

Given(/^well "([^"]*)" on plate "([^"]*)" has a genotyping_done status of "([^"]*)"$/) do |well_description, plate_barcode, genotyping_status|
  plate = Plate.find_by(barcode: plate_barcode)
  well = plate.find_well_by_name(well_description)
  well.primary_aliquot.sample.external_properties.create!(key: 'genotyping_done', value: genotyping_status)
end

Given /^well "([^"]*)" has a genotyping status of "([^"]*)"$/ do |uuid, genotyping_status|
  well = Uuid.find_by(external_id: uuid).resource

  sample = FactoryGirl.create(:sample, name: 'Testing_the_JSON_API')
  sample.external_properties.create!(key: 'genotyping_done', value: genotyping_status)
  sample.external_properties.create!(key: 'genotyping_snp_plate_id')

  well.aliquots.clear
  well.aliquots.create!(sample: sample)
end

Given(/^I have a DNA QC submission for plate "([^"]*)"$/) do |plate_barcode|
  step %Q{I have a "DNA QC" submission for plate "#{plate_barcode}" with project "Test project" and study "Study B"}
end

Given /^I have a "([^"]*)" submission for plate "([^"]*)" with project "([^"]*)" and study "([^"]*)"$/ do |submission_template_name, plate_barcode, project_name, study_name|
  plate = Plate.find_by(barcode: plate_barcode)
  project = Project.find_by(name: project_name)
  study = Study.find_by(name: study_name)

  # Maintain the order of the wells as though they have been submitted by the user, rather than
  # relying on the ordering within sequencescape.  Some of the plates are created with less than
  # the total wells needed (which is bad).
  wells = []
  plate.wells.walk_in_column_major_order { |well, _| wells << well }
  wells.compact!

  submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  submission = submission_template.create_and_build_submission!(
    study: study,
    project: project,
    workflow: Submission::Workflow.find_by(key: 'microarray_genotyping'),
    user: User.last,
    assets: wells
    )
  step('1 pending delayed jobs are processed')
end

Given /^I have a Cherrypicking submission for asset group "([^"]*)"$/ do |asset_group_name|
  project = Project.find_by(name: 'Test project')
  study = Study.find_by(name: 'Test study')
  asset_group = AssetGroup.find_by(name: asset_group_name)

  submission_template = SubmissionTemplate.find_by(name: 'Cherrypick')
  submission = submission_template.create_and_build_submission!(
    study: study,
    project: project,
    workflow: Submission::Workflow.find_by(key: 'microarray_genotyping'),
    user: User.last,
    assets: asset_group.assets
    )
  step('1 pending delayed jobs are processed')
end

Given /^the internal QC plates are created$/ do
  step('I follow "Pipelines"')
  step('I follow "Create Plate Barcodes"')
  step('I select "Pico Standard" from "Plate purpose"')
  step('I select "xyz" from "Barcode printer"')
  step('I fill in "User barcode" with "2470000100730"')
  step('I press "Submit"')
  step('I fill in "Source plates" with "1221234567841"')
  step('I fill in "User barcode" with "2470000100730"')
  step('I select "Working dilution" from "Plate purpose"')
  step('I select "xyz" from "Barcode printer"')
  step('I press "Submit"')
  step('I fill in "Source plates" with "6251234567836"')
  step('I fill in "User barcode" with "2470000100730"')
  step('I select "Pico dilution" from "Plate purpose"')
  step('I select "xyz" from "Barcode printer"')
  step('I press "Submit"')
  step('I fill in "Source plates" with "4361234567667"')
  step('I fill in "User barcode" with "2470000100730"')
  step('I select "Pico Assay Plates" from "Plate purpose"')
  step('I select "xyz" from "Barcode printer"')
  step('I press "Submit"')
  step('I fill in "Source plates" with "6251234567836"')
  step('I fill in "User barcode" with "2470000100730"')
  step('I select "Gel Dilution Plates" from "Plate purpose"')
  step('I select "xyz" from "Barcode printer"')
  step('I press "Submit"')
  step 'plate with barcode "4331234567653" is part of study "Test study"'
  step('plate with barcode "4341234567737" is part of study "Test study"')
  step('plate with barcode "1931234567771" is part of study "Test study"')
  step('5 pending delayed jobs are processed')

  # print sequenome barcode
  step('I am on the new Sequenom QC Plate page')
  step('I fill in "User barcode" with "2470000100730"')
  step('I fill in "Plate 1" with "6251234567836"')
  step('I fill in "Number of Plates" with "1"')
  step('I select "xyz" from "Barcode Printer"')
  step('I press "Create new Plate"')
  step('all pending delayed jobs are processed')
end
