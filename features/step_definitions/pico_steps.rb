Given /^the Stock Plate's Pico pass state is set to "([^"]*)"$/ do |current_state|
  current_state = nil if current_state.blank?
  @stock_plate.wells.first.well_attribute.update_attributes( :pico_pass => current_state )
end


When /^I post the JSON below to update the plate:$/ do |update_json|
  post(url_for(:controller => 'pico_set_results', :action => 'create'), update_json, 'Content-Type' => 'application/json')
end

Then /^well "([^"]*)" on plate "([^"]*)" should have a concentration of (\d+\.\d+)$/ do |well_description, raw_barcode, concentration|
  plate = Plate.find_from_machine_barcode(raw_barcode)
  well = plate.find_well_by_name(well_description)
  assert_equal well.get_concentration, concentration.to_f
end

Then /^the Stock Plate's Pico pass state is "([^"]*)"$/ do |pico_status|
  assert_equal pico_status, @stock_plate.wells.first.well_attribute.pico_pass
end

Given /^the "([^\"]+)" plate is created from the plate with barcode "([^\"]+)"$/ do |plate_purpose_name, barcode|
  creator = Plate::Creator.find_by_name(plate_purpose_name) or raise StandardError, "Cannot find plate purpose #{plate_purpose_name.inspect}"
  plates = creator.send(:create_plates, barcode, User.last)
  raise StandardError, "Appears that plates could not be created" if plates.blank?
end
