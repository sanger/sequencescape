# frozen_string_literal: true

Given(
  /^plate "([^"]*)" with (\d+) samples in study "([^"]*)" exists$/
) do |plate_barcode, number_of_samples, study_name|
  step(
    # rubocop:todo Layout/LineLength
    "I have a plate \"#{plate_barcode}\" in study \"#{study_name}\" with #{number_of_samples} samples in asset group \"Plate asset group #{plate_barcode}\""
    # rubocop:enable Layout/LineLength
  )
  step("plate \"#{plate_barcode}\" has concentration results")
  step("plate \"#{plate_barcode}\" has measured volume results")
end

Given(/^plate "([^"]*)" has concentration results$/) do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  plate.wells.each_with_index { |well, index| well.well_attribute.update!(concentration: index * 40) }
end

Given(/^plate "([^"]*)" has nonzero concentration results$/) do |plate_barcode|
  step("plate \"#{plate_barcode}\" has concentration results")

  plate = Plate.find_from_barcode(plate_barcode)
  plate.wells.each_with_index do |well, _index|
    well.well_attribute.update!(concentration: 1) if well.well_attribute.concentration == 0.0
  end
end

Given(/^plate "([^"]*)" has measured volume results$/) do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  plate.wells.each_with_index { |well, index| well.well_attribute.update!(measured_volume: index * 11) }
end

Given(/^I have a tag group called "([^"]*)" with (\d+) tags$/) do |tag_group_name, number_of_tags|
  FactoryBot.create :tag_group, name: tag_group_name, tag_count: number_of_tags.to_i
end

Given(/^I have a plate "([^"]*)" with the following wells:$/) do |plate_barcode, well_details|
  plate = FactoryBot.create :plate, barcode: plate_barcode
  well_details.hashes.each do |well_detail|
    well =
      Well.create!(map: Map.find_by(description: well_detail[:well_location], asset_size: plate.size), plate:)
    well.well_attribute.update!(
      concentration: well_detail[:measured_concentration],
      measured_volume: well_detail[:measured_volume]
    )
  end
end
