# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Then(/^I should see dna qc table:$/) do |expected_results_table|
  actual_table = table(fetch_table('table#sortable_batches'))
  actual_table.map_column!('Qc') { |_text| '' }
  expected_results_table.diff!(actual_table)
end

Given(/^a plate template exists$/) do
  FactoryGirl.create :plate_template
end

Given(/^a robot exists$/) do
  robot = FactoryGirl.create :robot
  robot.robot_properties.create(key: 'max_plates', value: '21')
end

Given(/^I have a plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/) do |plate_barcode, study_name, number_of_samples, asset_group_name|
  purpose = FactoryGirl.create :plate_purpose
  purpose_name = purpose.name
  step(%Q{I have a "#{purpose_name}" plate "#{plate_barcode}" in study "#{study_name}" with #{number_of_samples} samples in asset group "#{asset_group_name}"})
end

Given(/^I have a "([^"]*)" plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/) do |purpose_name, plate_barcode, study_name, number_of_samples, asset_group_name|
  study = Study.find_by(name: study_name)
  purpose = Purpose.find_by(name: purpose_name)
  plate = FactoryGirl.create(:plate, purpose: purpose, barcode: plate_barcode)

  asset_group = study.asset_groups.find_by(name: asset_group_name) || study.asset_groups.create!(name: asset_group_name)
  asset_group.assets << (1..number_of_samples.to_i).map do |index|
    FactoryGirl.create(:well, plate: plate, map_id: index).tap do |well|
      well.aliquots.create!(sample: FactoryGirl.create(:sample, name: "Sample_#{plate_barcode}_#{index}"),
                            study: study)
    end
  end
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
end

Given(/^I have a cherrypicked plate with barcode "([^"]*)" and plate purpose "([^"]*)"$/) do |plate_barcode, plate_purpose_name|
  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')
  step('I check "Select DN1234567T for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')
  step(%Q{a plate barcode webservice is available and returns "#{plate_barcode}"})
  step(%Q{I complete the cherrypicking batch with "#{plate_purpose_name}" plate purpose but dont release it})
  Delayed::Worker.new.work_off # Build the asset links to clear the delayed job queue
end

Given(/^well "([^"]*)" on plate "([^"]*)" has a genotyping_done status of "([^"]*)"$/) do |well_description, plate_barcode, genotyping_status|
  plate = Plate.find_from_barcode('DN' + plate_barcode)
  well = plate.find_well_by_name(well_description)
  well.primary_aliquot.sample.external_properties.create!(key: 'genotyping_done', value: genotyping_status)
end

Given(/^well "([^"]*)" has a genotyping status of "([^"]*)"$/) do |uuid, genotyping_status|
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

Given(/^I have a "([^"]*)" submission for plate "([^"]*)" with project "([^"]*)" and study "([^"]*)"$/) do |submission_template_name, plate_barcode, project_name, study_name|
  plate = Plate.find_from_barcode(plate_barcode)
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
    user: User.last,
    assets: wells
  )
  step('1 pending delayed jobs are processed')
end

Given(/^I have a Cherrypicking submission for asset group "([^"]*)"$/) do |asset_group_name|
  project = Project.find_by(name: 'Test project')
  study = Study.find_by(name: 'Test study')
  asset_group = AssetGroup.find_by(name: asset_group_name)

  submission_template = SubmissionTemplate.find_by(name: 'Cherrypick')
  submission = submission_template.create_and_build_submission!(
    study: study,
    project: project,
    user: User.last,
    assets: asset_group.assets
  )
  step('1 pending delayed jobs are processed')
end
