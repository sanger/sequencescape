# frozen_string_literal: true

require './spec/support/download_helper'

Given(
  /^I have a released cherrypicking batch with (\d+) samples and the minimum robot pick is "([^"]*)"$/
) do |number_of_samples, minimum_robot_pick|
  step("I have a cherrypicking batch with #{number_of_samples} samples")
  step('a plate barcode webservice is available and returns "SQPD-99999"')
  step('a plate template exists')
  step('a robot exists with barcode "444"')
  step('plate "SQPD-1234567" has concentration and volume results')
  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step('I select "Infinium 670k" from "Output plate purpose"')
  fill_in('nano_grams_per_micro_litre_volume_required', with: "13", fill_options: { clear: :backspace })
  step('I fill in "nano_grams_per_micro_litre_concentration_required" with "50"')
  fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_robot_pick)
  step('I press "Next step"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('the last batch has a barcode of "550000555760"')
end

Given(
  /^I have a released low concentration cherrypicking batch with (\d+) samples and the minimum robot pick is "([^"]*)"$/
) do |number_of_samples, minimum_robot_pick|
  step("I have a cherrypicking batch with #{number_of_samples} samples")
  step('a plate barcode webservice is available and returns "SQPD-99999"')
  step('a plate template exists')
  step('a robot exists with barcode "444"')
  step('plate "SQPD-1234567" has low concentration and volume results')
  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step('I select "Infinium 670k" from "Output plate purpose"')
  step('I fill in "nano_grams_per_micro_litre_volume_required" with "13"')
  step('I fill in "nano_grams_per_micro_litre_concentration_required" with "50"')
  fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_robot_pick)
  step('I press "Next step"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('the last batch has a barcode of "550000555760"')
end

# rubocop:disable Metrics/BlockLength
Given(
  /^I have a released cherrypicking batch with 3 plates and the minimum robot pick is "([^"]*)"$/
) do |minimum_robot_pick|
  step('I am a "administrator" user logged in as "user"')
  step('I have a project called "Test project"')
  step('I have an active study called "Test study"')
  step('I have a plate "SQPD-1" in study "Test study" with 2 samples in asset group "Plate asset group"')
  step('I have a plate "SQPD-10" in study "Test study" with 2 samples in asset group "Plate asset group"')
  step('I have a plate "SQPD-5" in study "Test study" with 2 samples in asset group "Plate asset group"')

  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')

  step('I check "Select SQPD-1 for batch"')
  step('I check "Select SQPD-10 for batch"')
  step('I check "Select SQPD-5 for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')

  # must use @javascript
  step('a plate barcode webservice is available and returns "SQPD-99999"')
  step('a plate template exists')
  step('a robot exists with barcode "444"')
  step('plate "SQPD-10" has concentration and volume results')
  step('plate "SQPD-1" has concentration and volume results')
  step('plate "SQPD-5" has concentration and volume results')

  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step('I select "Infinium 670k" from "Output plate purpose"')
  step('I fill in "nano_grams_per_micro_litre_volume_required" with "13"')
  step('I fill in "nano_grams_per_micro_litre_concentration_required" with "50"')
  fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_robot_pick)
  step('I press "Next step"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('the last batch has a barcode of "550000555760"')
end
# rubocop:enable Metrics/BlockLength

Given /^I have a released cherrypicking batch with 1 plate which doesnt need buffer$/ do
  step('I have a released cherrypicking batch with 1 samples and the minimum robot pick is "1"')
  plate = Plate.last
  plate.wells.each { |well| well.well_attribute.update!(buffer_volume: nil) }
end

Given /^user "([^"]*)" has a user barcode of "([^"]*)"$/ do |login, user_barcode|
  user = User.find_by(login:)
  user.update!(barcode: user_barcode)
end

# rubocop:todo Layout/LineLength
Then /^the downloaded robot file for batch "([^"]*)" and plate "([^"]*)" is$/ do |batch_barcode, plate_barcode, tecan_file|
  # rubocop:enable Layout/LineLength
  batch = Batch.find_by_barcode(batch_barcode) or
    raise StandardError, "Cannot find batch with barcode #{batch_barcode.inspect}"

  generated_file = DownloadHelpers.downloaded_file("#{batch.id}_batch_#{plate_barcode}_1.gwl")

  generated_lines = generated_file.lines(chomp: true)
  generated_lines.shift(2)
  assert_not_nil generated_lines
  tecan_file_lines = tecan_file.lines(chomp: true)
  generated_lines.each_with_index do |line, index|
    assert_equal tecan_file_lines[index], line, "Mismatch on line #{index + 2} in #{generated_file}"
  end
end

Then /^the source plates should be sorted by bed:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#source_beds')))
end
