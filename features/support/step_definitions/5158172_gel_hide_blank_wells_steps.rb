# frozen_string_literal: true

Given /^all wells on plate "([^"]*)" have non-empty sample names$/ do |plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.aliquots.clear
    well.aliquots.create!(sample: Sample.create!(name: "Sample_#{index}_on_#{plate_barcode}"))
  end
end

# rubocop:todo Layout/LineLength
Given /^well "([^"]*)" on plate "([^"]*)" has a sample name of "([^"]*)"$/ do |well_position, plate_barcode, sample_name|
  # rubocop:enable Layout/LineLength
  plate = Plate.find_from_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  well.aliquots.clear

  # This may be forcing the name of the sample so we cannot check validation here.
  sample = Sample.new(name: sample_name)
  sample.save(validate: false)
  well.aliquots.create!(sample: sample)
end

Given /^well "([^"]*)" on plate "([^"]*)" has an empty supplier sample name$/ do |well_position, plate_barcode|
  plate = Plate.find_from_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  well.aliquots.clear
  well.aliquots.create!(
    sample: Sample.create!(name: "Sample_#{well_position}_on_plate_#{plate_barcode}", empty_supplier_sample_name: true)
  )
end
