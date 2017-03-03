# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given /^the system has a plate with a barcode of "([^\"]*)"$/ do |encoded_barcode|
  FactoryGirl.create(:plate, barcode: Barcode.number_to_human(encoded_barcode))
end

Given /^exactly (\d+) labels? should have been printed/ do |expected_number|
  assert_equal(expected_number.to_i, FakeBarcodeService.instance.printed_barcodes!.size)
end

Given /^exactly (\d+) barcodes? different should have been sent to print/ do |expected_number|
  assert_equal(expected_number.to_i, FakeBarcodeService.instance.printed_barcodes!.uniq.size)
end

Given /^the study "([^\"]+)" has a plate with barcode "([^\"]+)"$/ do |study_name, barcode|
  study, user = Study.find_by(name: study_name), User.find_by(login: 'user')
  prefix, number, check = Barcode.split_human_barcode(barcode)

  asset_group = FactoryGirl.create(:asset_group, name: 'plates', user: user, study: study)
  plate = FactoryGirl.create(:plate, barcode: number)
  FactoryGirl.create(:asset_group_asset, asset_id: plate.id, asset_group_id: asset_group.id)
end

Given /^the plate with barcode "([^\"]+)" has events:$/ do |barcode, events_table|
  prefix, number, check = Barcode.split_human_barcode(barcode)
  plate = Plate.find_by(barcode: number) or raise "You must configure the plate with barcode '#{barcode}' first"
  events_table.hashes.each { |hash| plate.events.create!(hash) }
end

Given /^plate "([^"]*)" has "([^"]*)" wells$/ do |plate_barcode, number_of_wells|
  plate = Plate.find_by(barcode: plate_barcode)
  1.upto(number_of_wells.to_i) do |i|
    Well.create!(plate: plate, map_id: i)
  end
end

Given /^plate "([^"]*)" has "([^"]*)" wells with samples$/ do |plate_barcode, number_of_wells|
  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells = Array.new(number_of_wells.to_i) do |i|
    FactoryGirl.create(:untagged_well, map_id: i + 1)
  end
end

Then /^plate with barcode "([^"]*)" should exist$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate
end

Then /^plate with barcode "([^"]*)" is part of study "([^"]*)"$/ do |plate_barcode, study_name|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  assert_not_nil plate
  study = Study.find_by(name: study_name)
  assert_equal study, plate.study
end

Given /^plate "([^"]*)" has concentration and sequenom results$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  plate.wells.walk_in_column_major_order do |well, index|
    well.well_attribute.update_attributes!(
      pico_pass: 'Pass',
      concentration: 5 + (index % 50),
      sequenom_count: index % 30,
      gender_markers: %w(F F F F)
    )
  end
end

Given /^plate "([^\"]*)" has concentration and volume results$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(
      current_volume: 10 + (index % 30),
      concentration: 205 + (index % 50)
    )
  end
end

Given /^plate "([^\"]*)" has low concentration and volume results$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(
      current_volume: 10 + (index % 30),
      concentration: 50 + (index % 50)
    )
  end
end

Given /^plate "([^\"]*)" has concentration and high volume results$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(
      current_volume: 30 + (index % 30),
      concentration: 205 + (index % 50)
    )
  end
end

Given /^plate with barcode "([^"]*)" has a well$/ do |plate_barcode|
  plate = Plate.find_by(barcode: plate_barcode)
  well  = FactoryGirl.create(:empty_well).tap { |well| well.aliquots.create!(sample: FactoryGirl.create(:sample, name: 'Sample1')) }
  plate.add_and_save_well(well, 0, 0)
end

Then /^plate "([^"]*)" should have a child plate of type "([^"]*)"$/ do |machine_barcode, plate_type|
  plate = Asset.find_from_machine_barcode(machine_barcode)
  assert plate
  assert plate.child.is_a?(plate_type.constantize)
end

Then(/^output all plates for debugging purposes$/) do
  puts 'ALL PLATES:'
  p Plate.all.to_a
  puts 'ALL ASSETS:'
  p Asset.all.to_a
end

Given /^a plate of type "([^"]*)" with barcode "([^"]*)" exists$/ do |plate_type, machine_barcode|
  plate_type.constantize.create!(
    barcode: Barcode.number_to_human(machine_barcode.to_s),
    plate_purpose: "#{plate_type}Purpose".constantize.first)
end

Given /^a "([^"]*)" plate purpose and of type "([^"]*)" with barcode "([^"]*)" exists$/ do |plate_purpose_name, plate_type, machine_barcode|
  plate_type.constantize.create!(
    barcode: Barcode.number_to_human(machine_barcode.to_s),
    plate_purpose: PlatePurpose.find_by(name: plate_purpose_name),
    name: machine_barcode)
end

Given /^plate (\d+) has is a stock plate$/ do |plate_id|
  Plate.find(plate_id).update_attributes(plate_purpose: PlatePurpose.stock_plate_purpose)
end

Given /^the plate with ID (\d+) has a plate purpose of "([^\"]+)"$/ do |id, name|
  purpose = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
  Plate.find(id).update_attributes!(plate_purpose: purpose)
end

Given /^a plate with purpose "([^"]*)" and barcode "([^"]*)" exists$/ do |plate_purpose_name, machine_barcode|
  # Plate.create!(:barcode =>Barcode.number_to_human("#{machine_barcode}"), :plate_purpose => PlatePurpose.find_by_name(plate_purpose_name))
  FactoryGirl.create(:plate,
    barcode: Barcode.number_to_human(machine_barcode.to_s),
    plate_purpose: Purpose.find_by(name: plate_purpose_name)
    )
end

Given /^a stock plate with barcode "([^"]*)" exists$/ do |machine_barcode|
  @stock_plate = FactoryGirl.create(:plate,
    name: 'A_TEST_STOCK_PLATE',
    barcode: Barcode.number_to_human(machine_barcode.to_s),
    plate_purpose: PlatePurpose.find_by(name: 'Stock Plate')
  )
end

Then /^plate "([^"]*)" is the parent of plate "([^"]*)"$/ do |parent_plate_barcode, child_plate_barcode|
  parent_plate = Asset.find_from_machine_barcode(parent_plate_barcode)
  child_plate = Asset.find_from_machine_barcode(child_plate_barcode)
  assert parent_plate
  assert child_plate
  parent_plate.children << child_plate
  parent_plate.save!
end

Given /^the well with ID (\d+) is at position "([^\"]+)" on the plate with ID (\d+)$/ do |well_id, position, plate_id|
  plate = Plate.find(plate_id)
  map   = Map.where_description(position).where_plate_size(plate.size).where_plate_shape(plate.asset_shape).first or raise StandardError, "Could not find position #{position}"
  Well.find(well_id).update_attributes!(plate: plate, map: map)
end

Given /^well "([^"]*)" is holded by plate "([^"]*)"$/ do |well_uuid, plate_uuid|
  well = Uuid.find_by(external_id: well_uuid).resource
  plate = Uuid.find_by(external_id: plate_uuid).resource
  well.update_attributes!(plate: plate, map: Map.find_by(description: 'A1'))
  plate.update_attributes!(barcode: 1)
end

Then /^plate "([^"]*)" should have a purpose of "([^"]*)"$/ do |_plate_barcode, plate_purpose_name|
  assert_equal plate_purpose_name, Plate.find_by(barcode: '1234567').plate_purpose.name
end

Given /^the well with ID (\d+) contains the sample "([^\"]+)"$/ do |well_id, name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  well   = Well.find(well_id)
  well.aliquots.create!(sample: sample)
end

Then /^the wells with the following UUIDs should all be related to the same plate:$/ do |well_uuids|
  wells = Uuid.lookup_many_uuids(well_uuids.rows.map(&:first)).map(&:resource)

  plates_by_holder  = wells.map(&:plate).uniq
  plates_by_parents = wells.map(&:parents).flatten.uniq

  assert_equal(1, plates_by_holder.size, 'Incorrect plate count found for the wells')
  assert_equal(1, plates_by_parents.size, 'Incorrect parent count found for the wells')
  assert_equal(plates_by_holder, plates_by_parents, 'Plates and parents do not agree on well to plate relationship')
end

Given /^a "([^\"]+)" plate called "([^\"]+)" exists$/ do |name, plate_name|
  plate_purpose = PlatePurpose.find_by!(name: name)
  plate_purpose.create!(name: plate_name)
end

Given(/^a plate called "([^"]*)" exists with purpose "([^"]*)"$/) do |name, purpose_name|
  purpose = Purpose.find_by(name: purpose_name) || FactoryGirl.create(:plate_purpose, name: purpose_name)
  FactoryGirl.create(:plate, name: name, purpose: purpose)
end

Given /^a "([^\"]+)" plate called "([^\"]+)" exists with barcode "([^\"]+)"$/ do |name, plate_name, barcode|
  plate_purpose = PlatePurpose.find_by!(name: name)
  plate_purpose.create!(name: plate_name, barcode: barcode)
end

Given /^a "([^\"]+)" plate called "([^\"]+)" exists as a child of "([^\"]+)"$/ do |name, plate_name, parent_name|
  plate_purpose = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
  parent        = Plate.find_by(name: parent_name) or raise StandardError, "Cannot find parent plate #{parent_name.inspect}"
  AssetLink.create!(ancestor: parent, descendant: plate_purpose.create!(name: plate_name))
end

Given /^a "(.*?)" plate called "(.*?)" exists as a child of plate (\d+)$/ do |name, plate_name, parent_id|
  plate_purpose = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
  parent        = Plate.find(parent_id) or raise StandardError, "Cannot find parent plate #{parent_id.inspect}"
  AssetLink.create!(ancestor: parent, descendant: plate_purpose.create!(name: plate_name))
end

Given /^a "([^\"]+)" plate called "([^\"]+)" with ID (\d+)$/ do |name, plate_name, id|
  plate_purpose = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
  plate_purpose.create!(name: plate_name, id: id)
end

Given /^all wells on (the plate "[^\"]+") have unique samples$/ do |plate|
  plate.wells.each do |well|
    well.aliquots.create!(sample: FactoryGirl.create(:sample))
  end
end

Given /^([0-9]+) wells on (the plate "[^\"]+"|the last plate|the plate with ID [\d]+) have unique samples$/ do |number, plate|
  plate.wells.in_column_major_order[0, number.to_i].each do |well|
    well.aliquots.create!(sample: FactoryGirl.create(:sample))
  end
end

Given /^plate "([^"]*)" has "([^"]*)" wells with aliquots$/ do |plate_barcode, number_of_wells|
  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells = Array.new(number_of_wells.to_i) do |i|
    FactoryGirl.build :untagged_well, map_id: i + 1
  end
end

Given /^the plate "([^"]*)" is (passed|started|pending|failed) by "([^"]*)"$/ do |plate_name, state, user_name|
  plate = Plate.find_by(name: plate_name)
  user = User.find_by(login: user_name)
  StateChange.create!(user: user, target: plate, target_state: state)
end

Given /^(passed|started|pending|failed) transfer requests exist between (\d+) wells on "([^"]*)" and "([^"]*)"$/ do |state, count, source_name, dest_name|
  source = Plate.find_by(name: source_name)
  destination = Plate.find_by(name: dest_name)
  (0...count.to_i).each do |i|
    RequestType.transfer.create!(asset: source.wells.in_row_major_order[i], target_asset: destination.wells.in_row_major_order[i], state: state)
    Well::Link.create!(source_well: source.wells.in_row_major_order[i], target_well: destination.wells.in_row_major_order[i], type: 'stock')
  end
  AssetLink.create(ancestor: source, descendant: destination)
end

Then /^the plate with the barcode "(.*?)" should have a label of "(.*?)"$/ do |barcode, label|
  plate = Plate.find_by!(barcode: barcode)
  assert_equal label, plate.role
end

Given(/^the plate with ID (\d+) has a custom metadatum collection with UUID "(.*?)"$/) do |id, uuid|
    metadata = [FactoryGirl.build(:custom_metadatum, key: 'Key1', value: 'Value1'),
                FactoryGirl.build(:custom_metadatum, key: 'Key2', value: 'Value2')]
    collection = FactoryGirl.create(:custom_metadatum_collection, custom_metadata: metadata, asset_id: id)
    set_uuid_for(collection, uuid)
end

Then(/^the volume of each well in "(.*?)" should be:$/) do |machine, table|
  plate = Plate.with_machine_barcode(machine).first
  table.rows.each { |well, volume| assert_equal volume.to_f, plate.wells.located_at(well).first.get_current_volume }
end

Given /^I have a plate with uuid "([^"]*)" with the following wells:$/ do |uuid, well_details|
  # plate = FactoryGirl.create :plate, :barcode => plate_barcode
  plate = Uuid.find_by(external_id: uuid).resource
  well_details.hashes.each do |well_detail|
    well = Well.create!(map: Map.find_by(description: well_detail[:well_location], asset_size: 96), plate: plate)
    well.well_attribute.update_attributes!(concentration: well_detail[:measured_concentration], measured_volume: well_detail[:measured_volume])
  end
end

Then /^I should have a plate with uuid "([^"]*)" with the following wells volumes:$/ do |uuid, well_details|
  well_details.hashes.each do |well_detail|
    plate = Uuid.find_by(external_id: uuid).resource
    vol1 = plate.wells.select do |w|
      w.map.description == well_detail[:well_location]
    end.first.get_current_volume
    assert_equal well_detail[:current_volume].to_f, vol1
  end
end
