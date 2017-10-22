# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Then /^the plate "([^"]*)" and each well should have a 'gel_analysed' event$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate.events.find_by(family: 'gel_analysed')
  plate.wells.each do |well|
    assert_not_nil well.events.find_by(family: 'gel_analysed')
  end
end

Given /^plate "([^"]*)" is part of study "([^"]*)"$/ do |plate_barcode, study_name|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  study = Study.find_by(name: study_name)
  RequestFactory.create_assets_requests(plate.wells, study)
end

Then /^the plate "([^"]*)" should have a 'pico_analysed' event$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate.events.find_by(family: 'pico_analysed')
end

Then /^well "([^"]*)" on plate "([^"]*)" should have a 'pico_analysed' event$/ do |well_description, plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate.find_well_by_name(well_description).events.find_by(family: 'pico_analysed')
end
