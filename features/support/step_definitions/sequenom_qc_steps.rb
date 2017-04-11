# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

# TODO: Remove these methods from Plate because it's bad to do this in a test
class Plate
  def add_wells_to_plate(number_of_wells)
    sample = FactoryGirl.create(:sample)
    1.upto(number_of_wells.to_i) do |i|
      wells.create!(map_id: i).tap { |well| well.aliquots.create!(sample: sample) }
    end
  end

  def self.create_source_plates(source_barcodes, first_well_gender = true, number_of_wells = 96)
    source_barcodes.each do |encoded_barcode|
      plate = FactoryGirl.create(:plate, barcode: Barcode.number_to_human(encoded_barcode))
      plate.add_wells_to_plate(number_of_wells)

      # Unless we say otherwise give the first sample on the plate
      plate.wells.first.primary_aliquot.sample.sample_metadata.update_attributes!(
        gender: 'male'
      ) if first_well_gender
    end
  end
end

Given /^I am setup for sequenome QC$/ do
  @source_plate_barcodes = %w{1220125054743 1220125056761 1220125069815 1220125048766}
  Plate.create_source_plates(@source_plate_barcodes, true, 1)
end

Given /^I am setup for sequenome QC using plates "([^"]*)"$/ do |barcodes_string|
  Plate.create_source_plates(barcodes_string.split("\s"), true, 2)
end

Given /^I have a source plate which contains samples which have no gender information$/ do
  Plate.create_source_plates(%w{1220125054743}, false)
end

When /^I try to create a Sequenom QC plate from the input plate$/ do
  step('I fill in "Plate 1" with "1220125054743"')
  step('I fill in "User barcode" with "2470000100730"')
  step('I press "Create new Plate"')
end

When /^plate "([^"]*)" should have a size of (\d+)$/ do |plate_barcode, plate_size|
  assert_equal plate_size.to_i, Plate.find_by(barcode: plate_barcode).size
end

When /^well "([^"]*)" should come from well "([^"]*)" on plate "([^"]*)"$/ do |seq_well_description, source_well_description, plate_barcode|
  unless plate_barcode.blank?
    plate          = Plate.find_from_machine_barcode(plate_barcode)
    source_well    = plate.find_well_by_name(source_well_description)
    sequenom_plate = SequenomQcPlate.last
    sequenom_well  = sequenom_plate.find_well_by_name(seq_well_description)

    assert_not_nil sequenom_well
    assert_not_nil sequenom_well.primary_aliquot
    assert_equal source_well.primary_aliquot.sample, sequenom_well.primary_aliquot.sample
    assert source_well.children.map(&:id).include?(sequenom_well.id)
    assert plate.children.map(&:id).include?(sequenom_plate.id)
  end
end
