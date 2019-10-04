# frozen_string_literal: true

Given /^plate "([^"]*)" has "([^"]*)" wells$/ do |plate_barcode, number_of_wells|
  plate = Plate.find_from_barcode('DN' + plate_barcode)
  1.upto(number_of_wells.to_i) do |i|
    Well.create!(plate: plate, map_id: i)
  end
end

Then /^plate with barcode "([^"]*)" should exist$/ do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  assert_not_nil plate
end

Given /^plate "([^\"]*)" has concentration and volume results$/ do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update!(
      current_volume: 10 + (index % 30),
      concentration: 205 + (index % 50)
    )
  end
end

Given /^plate "([^\"]*)" has low concentration and volume results$/ do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update!(
      current_volume: 10 + (index % 30),
      concentration: 50 + (index % 50)
    )
  end
end

Given /^plate with barcode "([^"]*)" has a well$/ do |plate_barcode|
  plate = Plate.find_from_barcode('DN' + plate_barcode)
  map = plate.maps.first
  FactoryBot.create(:untagged_well, plate: plate, map: map)
end

Given 'a tube named {string} with barcode {string} exists' do |name, machine_barcode|
  FactoryBot.create :tube, name: name, sanger_barcode: { machine_barcode: machine_barcode }
end

Given /^a plate with barcode "([^"]*)" exists$/ do |machine_barcode|
  FactoryBot.create :plate, sanger_barcode: { machine_barcode: machine_barcode }
end

Given /^a "([^"]*)" plate purpose and of type "([^"]*)" with barcode "([^"]*)" exists$/ do |plate_purpose_name, plate_type, machine_barcode|
  plate_type.constantize.create!(
    sanger_barcode: { machine_barcode: machine_barcode },
    plate_purpose: PlatePurpose.find_by(name: plate_purpose_name),
    name: machine_barcode
  )
end

Given /^plate (\d+) has is a stock plate$/ do |plate_id|
  Plate.find(plate_id).update(plate_purpose: PlatePurpose.stock_plate_purpose)
end

Given /^the plate with ID (\d+) has a plate purpose of "([^\"]+)"$/ do |id, name|
  purpose = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
  Plate.find(id).update!(plate_purpose: purpose)
end

Given /^a plate with purpose "([^"]*)" and barcode "([^"]*)" exists$/ do |plate_purpose_name, machine_barcode|
  FactoryBot.create(:plate,
                    sanger_barcode: { machine_barcode: machine_barcode },
                    well_count: 8,
                    plate_purpose: Purpose.find_by(name: plate_purpose_name))
end

Given /^a stock plate with barcode "([^"]*)" exists$/ do |machine_barcode|
  @stock_plate = FactoryBot.create(:plate,
                                   name: 'A_TEST_STOCK_PLATE',
                                   well_count: 8,
                                   sanger_barcode: { machine_barcode: machine_barcode },
                                   plate_purpose: PlatePurpose.find_by(name: 'Stock Plate'))
end

Then /^plate "([^"]*)" is the parent of plate "([^"]*)"$/ do |parent_plate_barcode, child_plate_barcode|
  parent_plate = Plate.find_by_barcode(parent_plate_barcode)
  child_plate = Plate.find_by_barcode(child_plate_barcode)
  assert parent_plate
  assert child_plate
  parent_plate.children << child_plate
  parent_plate.save!
end

Given /^the well with ID (\d+) is at position "([^\"]+)" on the plate with ID (\d+)$/ do |well_id, position, plate_id|
  plate = Plate.find(plate_id)
  map   = Map.where_description(position).where_plate_size(plate.size).where_plate_shape(plate.asset_shape).first or raise StandardError, "Could not find position #{position}"
  Well.find(well_id).update!(plate: plate, map: map)
end

Given /^well "([^"]*)" is holded by plate "([^"]*)"$/ do |well_uuid, plate_uuid|
  well = Uuid.find_by(external_id: well_uuid).resource
  plate = Uuid.find_by(external_id: plate_uuid).resource
  well.update!(plate: plate, map: Map.find_by(description: 'A1'))
  step("the barcode for plate #{plate.id} is \"DN1S\"")
end

Then /^plate "([^"]*)" should have a purpose of "([^"]*)"$/ do |plate_barcode, plate_purpose_name|
  assert_equal plate_purpose_name, Plate.find_from_barcode("DN#{plate_barcode}").plate_purpose.name
end

Given /^a "([^\"]+)" plate called "([^\"]+)" exists$/ do |name, plate_name|
  plate_purpose = PlatePurpose.find_by!(name: name)
  plate_purpose.create!(name: plate_name)
end

Given(/^a plate called "([^"]*)" exists with purpose "([^"]*)"$/) do |name, purpose_name|
  purpose = Purpose.find_by(name: purpose_name) || FactoryBot.create(:plate_purpose, name: purpose_name)
  FactoryBot.create(:plate, name: name, purpose: purpose, well_count: 8)
end

Given(/^a full plate called "([^"]*)" exists with purpose "([^"]*)" and barcode "([^"]*)"$/) do |name, purpose_name, barcode|
  purpose = Purpose.find_by(name: purpose_name) || FactoryBot.create(:plate_purpose, name: purpose_name)
  FactoryBot.create(:full_plate, well_factory: :untagged_well, name: name, purpose: purpose, barcode: barcode, well_count: 16)
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

Given 'all wells on {plate_name} have unique samples' do |plate|
  plate.wells.each do |well|
    FactoryBot.create :untagged_aliquot, receptacle: well
  end
end

# Given /^([0-9]+) wells on (the plate "[^\"]+"|the last plate|the plate with ID [\d]+) have unique samples$/ do |number, plate|
#   plate.wells.in_column_major_order[0, number.to_i].each do |well|
#     FactoryBot.create :untagged_aliquot, receptacle: well
#   end
# end

Given '{int} wells on {plate_name} have unique samples' do |number, plate|
  plate.wells.in_column_major_order[0, number].each do |well|
    FactoryBot.create :untagged_aliquot, receptacle: well
  end
end

Given '{int} wells on {plate_id} have unique samples' do |number, plate|
  plate.wells.in_column_major_order[0, number].each do |well|
    FactoryBot.create :untagged_aliquot, receptacle: well
  end
end

Given /^plate "([^"]*)" has "([^"]*)" wells with aliquots$/ do |plate_barcode, number_of_wells|
  plate = Plate.find_from_barcode('DN' + plate_barcode)
  plate.wells = Array.new(number_of_wells.to_i) do |i|
    FactoryBot.build :untagged_well, map_id: i + 1
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
  count.to_i.times do |i|
    FactoryBot.create(:transfer_request, asset: source.wells.in_row_major_order[i], target_asset: destination.wells.in_row_major_order[i], state: state)
    Well::Link.create!(source_well: source.wells.in_row_major_order[i], target_well: destination.wells.in_row_major_order[i], type: 'stock')
  end
  AssetLink.create(ancestor: source, descendant: destination)
end

Then /^the plate with the barcode "(.*?)" should have a label of "(.*?)"$/ do |barcode, label|
  plate = Plate.find_from_barcode('DN' + barcode)
  assert_equal label, plate.role
end

Then(/^the volume of each well in "(.*?)" should be:$/) do |machine, table|
  plate = Plate.with_barcode(machine).first
  table.rows.each { |well, volume| assert_equal volume.to_f, plate.wells.located_at(well).first.get_current_volume }
end

Given /^I have a plate with uuid "([^"]*)" with the following wells:$/ do |uuid, well_details|
  # plate = FactoryBot.create :plate, :barcode => plate_barcode
  plate = Uuid.find_by(external_id: uuid).resource
  well_details.hashes.each do |well_detail|
    well = Well.create!(map: Map.find_by(description: well_detail[:well_location], asset_size: 96), plate: plate)
    well.well_attribute.update!(concentration: well_detail[:measured_concentration], measured_volume: well_detail[:measured_volume])
  end
end

Then /^I should have a plate with uuid "([^"]*)" with the following wells volumes:$/ do |uuid, well_details|
  well_details.hashes.each do |well_detail|
    plate = Uuid.find_by(external_id: uuid).resource
    vol1 = plate.wells.find do |w|
      w.map.description == well_detail[:well_location]
    end.get_current_volume
    assert_equal well_detail[:current_volume].to_f, vol1
  end
end
