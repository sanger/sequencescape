class Plate
  def add_wells_to_plate(number_of_wells)
    well_data = []
    
    sample = Factory(:sample)
    
    1.upto(number_of_wells.to_i) do |i|
      well_data  << wells.new(
        :map_id => i,
        :sample => sample
      )
    end
    wells.import well_data
  end

  def self.create_source_plates(source_barcodes, first_well_gender=true, number_of_wells = 96)
    source_barcodes.each do |encoded_barcode|
      plate = Factory.create(:plate, :barcode => Barcode.number_to_human(encoded_barcode))
      plate.add_wells_to_plate(number_of_wells)

      # Unless we say otherwise give the first sample on the plate
      plate.wells.first.material.sample_metadata.update_attributes!(
        :gender => "male"
      ) if first_well_gender
    end
  end
end



Given /^I am setup for sequenome QC$/ do
  @source_plate_barcodes = %w{1220125054743 1220125056761 1220125069815 1220125048766}
  Plate.create_source_plates(@source_plate_barcodes, true, 1)
end

Given /^I am setup for sequenome QC using plates "([^"]*)"$/ do |barcodes_string|
  Plate.create_source_plates(barcodes_string.split("\s"),true, 2)
end


Given /^I have a source plate which contains samples which have no gender information$/ do
  Plate.create_source_plates(%w{1220125054743},false)
end

When /^I try to create a Sequenom QC plate from the input plate$/ do
  When %Q{I fill in "Plate 1" with "1220125054743"}
  And %Q{I fill in "User barcode" with "2470000100730"}
  And %Q{I press "Create new Plate"}
end


When /^plate "([^"]*)" should have a size of (\d+)$/ do |plate_barcode, plate_size|
  assert_equal plate_size.to_i, Plate.find_by_barcode(plate_barcode).size
end

When /^well "([^"]*)" should come from well "([^"]*)" on plate "([^"]*)"$/ do |seq_well_description, source_well_description, plate_barcode|
  unless plate_barcode.blank?
    plate          = Plate.find_from_machine_barcode(plate_barcode)
    source_well    = plate.find_well_by_name(source_well_description)
    sequenom_plate = SequenomQcPlate.last
    sequenom_well  = sequenom_plate.find_well_by_name(seq_well_description)

    assert sequenom_well
    assert_equal source_well.sample, sequenom_well.sample
    assert !  sequenom_well.sample.nil?
    assert source_well.children.map{ |p| p.id }.include?(sequenom_well.id)
    assert plate.children.map{ |p| p.id }.include?(sequenom_plate.id)
  end
end

