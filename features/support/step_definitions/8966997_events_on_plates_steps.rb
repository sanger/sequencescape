# frozen_string_literal: true

Then /^the plate "([^"]*)" and each well should have a 'gel_analysed' event$/ do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  assert_not_nil plate.events.find_by(family: 'gel_analysed')
  plate.wells.each do |well|
    assert_not_nil well.events.find_by(family: 'gel_analysed')
  end
end

Given /^plate "([^"]*)" is part of study "([^"]*)"$/ do |plate_barcode, study_name|
  plate = Plate.find_from_barcode(plate_barcode)
  study = Study.find_by(name: study_name)
  RequestFactory.create_assets_requests(plate.wells, study)
end

Then /^the plate "([^"]*)" should have a 'pico_analysed' event$/ do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  assert_not_nil plate.events.find_by(family: 'pico_analysed')
end

Then /^well "([^"]*)" on plate "([^"]*)" should have a 'pico_analysed' event$/ do |well_description, plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  assert_not_nil plate.find_well_by_name(well_description).events.find_by(family: 'pico_analysed')
end
