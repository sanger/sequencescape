Then /^the plate "([^"]*)" and each well should have a 'gel_analysed' event$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate.events.find_by_family('gel_analysed')
  plate.wells.each do |well|
    assert_not_nil well.events.find_by_family('gel_analysed')
  end
end

Given /^plate "([^"]*)" is part of study "([^"]*)"$/ do |plate_barcode, study_name|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  study = Study.find_by_name(study_name)
  RequestFactory.create_assets_requests(plate.wells.map(&:id), study.id)
end

Then /^the plate "([^"]*)" should have a 'pico_analysed' event$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate.events.find_by_family('pico_analysed')
end

Then /^well "([^"]*)" on plate "([^"]*)" should have a 'pico_analysed' event$/ do |well_description, plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate.find_well_by_name(well_description).events.find_by_family('pico_analysed')
end
