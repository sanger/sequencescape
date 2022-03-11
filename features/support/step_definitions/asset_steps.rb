# frozen_string_literal: true

Given /^the barcode for the sample tube "([^"]+)" is "([^"]+)"$/ do |name, barcode|
  sample_tube = SampleTube.find_by!(name: name)
  sample_tube.primary_barcode.update!(barcode: barcode)
end

Given /^the barcode for the asset "([^"]+)" is "([^"]+)"$/ do |name, barcode|
  Barcode.find_by(barcode: barcode)&.destroy
  asset = Labware.find_by!(name: name)
  if asset.primary_barcode
    asset.primary_barcode.update!(barcode: barcode)
  else
    asset.barcodes << FactoryBot.create(:sanger_ean13_tube, barcode: barcode)
  end
end

Given /^tube "([^"]*)" has a public name of "([^"]*)"$/ do |name, public_name|
  Labware.find_by(name: name).update!(public_name: public_name)
end

Given /^(?:I have )?a phiX tube called "([^"]+)"$/ do |name|
  FactoryBot.create(:sample_tube, name: name, study: nil, project: nil)
end

Given /^(?:I have )?a (sample|library) tube called "([^"]+)"$/ do |tube_type, name|
  FactoryBot.create(:"#{tube_type}_tube", name: name)
end

Given 'I have an empty library tube called {string}' do |name|
  FactoryBot.create(:empty_library_tube, name: name)
end

Then 'the name of {uuid} should be {string}' do |asset, name|
  assert_equal(name, asset.name)
end

Given /^there is an asset link between "([^"]*)" and "([^"]*)"$/ do |source, target|
  source_plate = Plate.find_by(name: source)
  target_plate = Plate.find_by(name: target)
  AssetLink.create_edge(source_plate, target_plate)
  target_plate.wells.each do |target_well|
    source_well = source_plate.wells.located_at(target_well.map_description).first
    Well::Link.create!(target_well: target_well, source_well: source_well, type: 'stock')
  end
end
