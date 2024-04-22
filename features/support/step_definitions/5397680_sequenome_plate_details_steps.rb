# frozen_string_literal: true

# rubocop:todo Layout/LineLength
Given /^there is a (\d+) well "([^"]*)" plate with a barcode of "([^"]*)"$/ do |number_of_wells, plate_purpose_name, plate_barcode|
  # rubocop:enable Layout/LineLength
  new_plate =
    FactoryBot.create :plate,
                      sanger_barcode: Barcode.build_sanger_code39({ machine_barcode: plate_barcode }),
                      plate_purpose: PlatePurpose.find_by(name: plate_purpose_name)

  sample = FactoryBot.create :sample_with_gender, name: "#{plate_barcode}_x"

  1.upto(number_of_wells.to_i) { |i| new_plate.wells.create!(map_id: i).aliquots.create!(sample:) }
end

Given(/^plate "([^"]*)" has (\d+) blank samples$/) do |plate_barcode, number_of_blanks|
  plate = Plate.find_from_barcode(plate_barcode)
  study = plate.studies.first # we need to propagate the study to the new aliquots
  plate.wells.each_with_index do |well, index|
    break if index >= number_of_blanks.to_i

    well.aliquots.clear
    well.aliquots.create!(
      sample: Sample.create!(name: "#{plate_barcode}_#{index}", empty_supplier_sample_name: true),
      study:
    )
  end
end
