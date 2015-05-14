#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
Then /^the overview of the plates should look like:$/ do |expected_results_table|
   expected_results_table.diff!(table(fetch_table('table#qc_overview_table')))
end

Then /^I create a "([^"]*)" from plate "([^"]*)"$/ do |plate_types, source_plate|
  step(%Q{I fill in "Source plates" with "#{source_plate}"})
  step(%Q{I select "#{plate_types}" from "Plate purpose"})
  step(%Q{I select "xyz" from "Barcode printer"})
  step(%Q{I fill in "User barcode" with "2470000100730"})
  step(%Q{I press "Submit"})
end

Given /^plate "([^"]*)" has had pico analysis results uploaded$/ do |barcode|
  plate = Asset.find_from_machine_barcode(barcode)
  plate.events.create_pico!('passed')
end


Given /^plate "([^"]*)" has gel analysis results$/ do |barcode|
  plate = Asset.find_from_machine_barcode(barcode)
  plate.events.create_gel_qc!('passed',User.last)
end
