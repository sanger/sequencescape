# frozen_string_literal: true

Given(/^a plate template exists$/) { FactoryBot.create :plate_template }

Given(/^a robot exists$/) do
  robot = FactoryBot.create :robot
  robot.robot_properties.create(key: 'max_plates', value: '21')
end

Given(
  /^I have a plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/
) do |plate_barcode, study_name, number_of_samples, asset_group_name|
  purpose = FactoryBot.create :plate_purpose
  purpose_name = purpose.name
  step(
    # rubocop:todo Layout/LineLength
    "I have a \"#{purpose_name}\" plate \"#{plate_barcode}\" in study \"#{study_name}\" with #{number_of_samples} samples in asset group \"#{asset_group_name}\""
    # rubocop:enable Layout/LineLength
  )
end

Given(
  /^I have a "([^"]*)" plate "([^"]*)" in study "([^"]*)" with (\d+) samples in asset group "([^"]*)"$/
) do |purpose_name, plate_barcode, study_name, number_of_samples, asset_group_name|
  study = Study.find_by(name: study_name)
  purpose = Purpose.find_by(name: purpose_name)
  sanger_barcode = Barcode.build_sequencescape22({ barcode: plate_barcode })
  plate = FactoryBot.create(:plate, purpose:, sanger_barcode:)

  asset_group = study.asset_groups.find_by(name: asset_group_name) || study.asset_groups.create!(name: asset_group_name)
  asset_group.assets << (1..number_of_samples.to_i).map do |index|
    FactoryBot
      .create(:well, plate: plate, map_id: index)
      .tap do |well|
        well.aliquots.create!(
          sample: FactoryBot.create(:sample, name: "Sample_#{plate_barcode}_#{index}"),
          study: study
        )
      end
  end
end

Given(/^I have a cherrypicking batch with (\d+) samples$/) do |number_of_samples|
  step('I am a "administrator" user logged in as "user"')
  step('I have a project called "Test project"')
  step('I have an active study called "Test study"')
  step(
    # rubocop:todo Layout/LineLength
    "I have a plate \"SQPD-1234567\" in study \"Test study\" with #{number_of_samples} samples in asset group \"Plate asset group\""
    # rubocop:enable Layout/LineLength
  )

  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')

  step('I check "Select SQPD-1234567 for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')
end

Given(/^a robot exists with barcode "([^"]*)"$/) do |robot_barcode|
  robot = FactoryBot.create :robot, barcode: robot_barcode
  robot.robot_properties.create(key: 'max_plates', value: '21')
  robot.robot_properties.create(key: 'SCRC1', value: '1')
  robot.robot_properties.create(key: 'SCRC2', value: '2')
  robot.robot_properties.create(key: 'SCRC3', value: '3')
  robot.robot_properties.create(key: 'DEST1', value: '20')
end

When(/^I complete the cherrypicking batch with "([^"]*)" plate purpose but dont release it$/) do |plate_purpose_name|
  step('I follow "Select Plate Template"')
  step('I select "test_plate_template" from "Plate Template"')
  step("I select \"#{plate_purpose_name}\" from \"Output plate purpose\"")
  step('I press "Next step"')
  step('I press "Next step"')
end

Given(
  /^I have a cherrypicked plate with barcode "([^"]*)" and plate purpose "([^"]*)"$/
) do |plate_barcode, plate_purpose_name|
  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')
  step('I check "Select SQPD-1234567 for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')
  step("a plate barcode webservice is available and returns \"#{plate_barcode}\"")
  step("I complete the cherrypicking batch with \"#{plate_purpose_name}\" plate purpose but dont release it")
  Delayed::Worker.new.work_off # Build the asset links to clear the delayed job queue
end

Given(
  /^I have a "([^"]*)" submission for plate "([^"]*)" with project "([^"]*)" and study "([^"]*)"$/
) do |submission_template_name, plate_barcode, project_name, study_name|
  plate = Plate.find_from_barcode(plate_barcode)
  project = Project.find_by(name: project_name)
  study = Study.find_by(name: study_name)

  # Maintain the order of the wells as though they have been submitted by the user, rather than
  # relying on the ordering within sequencescape.  Some of the plates are created with less than
  # the total wells needed (which is bad).
  wells = plate.wells.in_column_major_order.to_a

  submission_template = SubmissionTemplate.find_by!(name: submission_template_name)
  order = submission_template.create_with_submission!(study: study, project: project, user: User.last, assets: wells)
  order.submission.built!
  step('1 pending delayed jobs are processed')
end

Given(/^I have a Cherrypicking submission for asset group "([^"]*)"$/) do |asset_group_name|
  project = Project.find_by(name: 'Test project')
  study = Study.find_by(name: 'Test study')
  asset_group = AssetGroup.find_by(name: asset_group_name)

  submission_template = SubmissionTemplate.find_by!(name: 'Cherrypick')
  order =
    submission_template.create_with_submission!(
      study: study,
      project: project,
      user: User.last,
      assets: asset_group.assets
    )
  order.submission.built!
  step('1 pending delayed jobs are processed')
end
