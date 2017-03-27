# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given /^I have a released cherrypicking batch$/ do
  step("I have a released cherrypicking batch with 96 samples and the minimum robot pick is '1.0'")
end

Given(/^I have a released cherrypicking batch with (\d+) samples and the minimum robot pick is "([^"]*)"$/) do |number_of_samples, minimum_robot_pick|
  step("I have a cherrypicking batch with #{number_of_samples} samples")
  step('a plate barcode webservice is available and returns "99999"')
  step('a plate template exists')
  step('a robot exists with barcode "444"')
  step('plate "1221234567841" has concentration and volume results')
  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step('I select "Infinium 670k" from "Output plate purpose"')
  step('I fill in "nano_grams_per_micro_litre_volume_required" with "13"')
  step('I fill in "nano_grams_per_micro_litre_concentration_required" with "50"')
  fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_robot_pick)
  step('I press "Next step"')
  step('I press "Next step"')
  step('I select "Genotyping freezer" from "Location"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('the last batch has a barcode of "550000555760"')
end

Given(/^I have a released low concentration cherrypicking batch with (\d+) samples and the minimum robot pick is "([^"]*)"$/) do |number_of_samples, minimum_robot_pick|
  step("I have a cherrypicking batch with #{number_of_samples} samples")
  step('a plate barcode webservice is available and returns "99999"')
  step('a plate template exists')
  step('a robot exists with barcode "444"')
  step('plate "1221234567841" has low concentration and volume results')
  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step('I select "Infinium 670k" from "Output plate purpose"')
  step('I fill in "nano_grams_per_micro_litre_volume_required" with "13"')
  step('I fill in "nano_grams_per_micro_litre_concentration_required" with "50"')
  fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_robot_pick)
  step('I press "Next step"')
  step('I press "Next step"')
  step('I select "Genotyping freezer" from "Location"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('the last batch has a barcode of "550000555760"')
end

Given(/^I have a released cherrypicking batch with 3 plates and the minimum robot pick is "([^"]*)"$/) do |minimum_robot_pick|
  step('I am a "administrator" user logged in as "user"')
  step('I have a project called "Test project"')
  step('I have an active study called "Test study"')
  step('I have a plate "1" in study "Test study" with 2 samples in asset group "Plate asset group"')
  step('I have a plate "10" in study "Test study" with 2 samples in asset group "Plate asset group"')
  step('I have a plate "5" in study "Test study" with 2 samples in asset group "Plate asset group"')

  step('I have a Cherrypicking submission for asset group "Plate asset group"')
  step('I am on the show page for pipeline "Cherrypick"')

  step('I check "Select DN1S for batch"')
  step('I check "Select DN10I for batch"')
  step('I check "Select DN5W for batch"')
  step('I select "Create Batch" from the first "action_on_requests"')
  step('I press the first "Submit"')

  # must use @javascript
  step('a plate barcode webservice is available and returns "99999"')
  step('a plate template exists')
  step('a robot exists with barcode "444"')
  step('plate "1220000010734" has concentration and volume results')
  step('plate "1220000001831" has concentration and volume results')
  step('plate "1220000005877" has concentration and volume results')

  step('I follow "Select Plate Template"')
  step('I select "testtemplate" from "Plate Template"')
  step('I select "Infinium 670k" from "Output plate purpose"')
  step('I fill in "nano_grams_per_micro_litre_volume_required" with "13"')
  step('I fill in "nano_grams_per_micro_litre_concentration_required" with "50"')
  fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_robot_pick)
  step('I press "Next step"')
  step('I press "Next step"')
  step('I select "Genotyping freezer" from "Location"')
  step('I press "Next step"')
  step('I press "Release this batch"')
  step('the last batch has a barcode of "550000555760"')
end

Given /^I have a released cherrypicking batch with 1 plate which doesnt need buffer$/ do
  step('I have a released cherrypicking batch with 1 samples and the minimum robot pick is "1"')
  plate = Plate.last
  plate.wells.each { |well| well.well_attribute.update_attributes!(buffer_volume: nil) }
end

Given /^user "([^"]*)" has a user barcode of "([^"]*)"$/ do |login, user_barcode|
  user = User.find_by(login: login)
  user.update_attributes!(barcode: user_barcode)
end

Transform /^the last batch$/ do |_|
  Batch.last or raise StandardError, 'There appear to be no batches'
end

Then /^the downloaded tecan file for batch "([^"]*)" and plate "([^"]*)" is$/ do |batch_barcode, plate_barcode, tecan_file|
  batch = Batch.find_by(barcode: Barcode.number_to_human(batch_barcode)) or raise StandardError, "Cannot find batch with barcode #{batch_barcode.inspect}"
  plate = Plate.find_from_machine_barcode(plate_barcode) or raise StandardError, "Cannot find plate with machine barcode #{plate_barcode.inspect}"
  generated_file = batch.tecan_gwl_file_as_text(plate.barcode, batch.total_volume_to_cherrypick, 'ABgene 0765')
  generated_lines = generated_file.split(/\n/)
  generated_lines.shift(2)
  assert_not_nil generated_lines
  tecan_file_lines = tecan_file.split(/\n/)
  generated_lines.each_with_index do |line, index|
    if defined?(JRuby)
      assert_equal tecan_file_lines[index], line
    else
      # MRI and Jruby have different float rounding behaviour
      # Both are valid, here we relax constraints for MRI.
      # The relaxed constraints are a little more permissive than
      # would be ideal.
      _expect_line, expect_root, expect_round = /(.*)(\.\d)/.match(tecan_file_lines[index])
      _actual_line, actual_root, actual_round = /(.*)(\.\d)/.match(line)
      assert_equal expect_root, actual_root
      valid_end = (expect_round == actual_round) || # The rounded digets match
                  (expect_round.to_i - actual_round.to_i == 1) && (actual_round.to_i.even?) # The digit has been rounded down to even
        assert valid_end
    end
  end
end

Then /^the source plates should be sorted by bed:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#source_beds')))
end

Given /^the minimum robot pick is ([0-9\.]+)$/ do |volume|
  configatron.tecan_minimum_volume = volume.to_f
end

Before('@tecan') do
  @cache_tecan_minimum = configatron.tecan_minimum_volume
end

After('@tecan') do
  configatron.tecan_minimum_volume = @cache_tecan_minimum
end
