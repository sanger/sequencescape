Given /^I have a released cherrypicking batch$/ do
  Given %Q{I have a released cherrypicking batch with 96 samples}
end

Given /^I have a released cherrypicking batch with (\d+) samples$/ do |number_of_samples|
  Given %Q{I have a cherrypicking batch with #{number_of_samples} samples}
  Given %Q{a plate barcode webservice is available and returns "99999"}
  Given %Q{a plate template exists}
  Given %Q{a robot exists with barcode "444"}
  Given %Q{plate "1221234567841" has concentration and volume results}
  When %Q{I follow "Start batch"}
  When %Q{I select "testtemplate" from "Plate Template"}
  And %Q{I fill in "Volume Required" with "13"}
  And %Q{I fill in "Concentration Required" with "50"}
  When %Q{I press "Next step"}
  When %Q{I press "Next step"}
  When %Q{I select "Infinium 670k" from "Plate Purpose"}
  And %Q{I press "Next step"}
  When %Q{I select "Genotyping freezer" from "Location"}
  And %Q{I press "Next step"}
  When %Q{I press "Release this batch"}
  Given %Q{the last batch has a barcode of "550000555760"}
end


Given /^I have a released cherrypicking batch with 3 plates$/ do
  Given %Q{I am a "administrator" user logged in as "user"}
  Given %Q{I have a project called "Test project"}
  And %Q{project "Test project" has enough quotas}
  Given %Q{I have an active study called "Test study"}
  Given %Q{I have a plate "1" in study "Test study" with 2 samples in asset group "Plate asset group"}
  Given %Q{I have a plate "10" in study "Test study" with 2 samples in asset group "Plate asset group"}
  Given %Q{I have a plate "5" in study "Test study" with 2 samples in asset group "Plate asset group"}

  Given %Q{I have a Cherrypicking submission for asset group "Plate asset group"}
  Given %Q{I am on the show page for pipeline "Cherrypick"}

  When %Q{I check "Select DN1S for batch"}
  When %Q{I check "Select DN10I for batch"}
  When %Q{I check "Select DN5W for batch"}
  And %Q{I select "Create Batch" from "action_on_requests"}
  And %Q{I press "Submit"}

  # must use @javascript
  Given %Q{a plate barcode webservice is available and returns "99999"}
  Given %Q{a plate template exists}
  Given %Q{a robot exists with barcode "444"}
  Given %Q{plate "1220000010734" has concentration and volume results}
  Given %Q{plate "1220000001831" has concentration and volume results}
  Given %Q{plate "1220000005877" has concentration and volume results}

  When %Q{I follow "Start batch"}
  When %Q{I select "testtemplate" from "Plate Template"}
  And %Q{I fill in "Volume Required" with "13"}
  And %Q{I fill in "Concentration Required" with "50"}
  When %Q{I press "Next step"}
  When %Q{I press "Next step"}
  When %Q{I select "Infinium 670k" from "Plate Purpose"}
  And %Q{I press "Next step"}
  When %Q{I select "Genotyping freezer" from "Location"}
  And %Q{I press "Next step"}
  When %Q{I press "Release this batch"}
  Given %Q{the last batch has a barcode of "550000555760"}
end

Given /^I have a released cherrypicking batch with 1 plate which doesnt need buffer$/ do
  Given %Q{I have a released cherrypicking batch with 1 samples}
  plate = Plate.last
  plate.wells.each { |well| well.well_attribute.update_attributes!(:buffer_volume => nil) }
end

Given /^user "([^"]*)" has a user barcode of "([^"]*)"$/ do |login, user_barcode|
  user = User.find_by_login(login)
  user.update_attributes!(:barcode => user_barcode)
end

Transform /^the last batch$/ do |_|
  Batch.last or raise StandardError, 'There appear to be no batches'
end

Then /^the downloaded tecan file for batch "([^"]*)" and plate "([^"]*)" is$/ do |batch_barcode, plate_barcode, tecan_file|
  batch = Batch.find_by_barcode(Barcode.number_to_human(batch_barcode)) or raise StandardError, "Cannot find batch with barcode #{batch_barcode.inspect}"
  plate = Plate.find_from_machine_barcode(plate_barcode)                or raise StandardError, "Cannot find plate with machine barcode #{plate_barcode.inspect}"
  generated_file = batch.tecan_gwl_file_as_text(plate.barcode, batch.total_volume_to_cherrypick, "ABgene 0765")
  generated_lines = generated_file.split(/\n/)
  generated_lines.shift(2)
  assert_not_nil generated_lines
  tecan_file_lines  = tecan_file.split(/\n/)
  generated_lines.each_with_index do |line,index|
    assert_equal tecan_file_lines[index], line
  end
end

Then /^the source plates should be sorted by bed:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#source_beds tr', 'td,th')))
end
