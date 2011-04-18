Given /^all wells on plate "([^"]*)" have non\-empty sample names$/ do |plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  plate.wells.each_with_index do |well,index|
    well.sample = Sample.create(:name => "Sample_#{index}_on_#{plate_barcode}")
    well.save!
  end
end

Given /^well "([^"]*)" on plate "([^"]*)" has a sample name of "([^"]*)"$/ do |well_position, plate_barcode, sample_name|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  well.sample = Sample.create(:name => sample_name)
  well.save!
end

Given /^well "([^"]*)" on plate "([^"]*)" has an empty supplier sample name$/ do |well_position, plate_barcode|
  plate = Plate.find_from_machine_barcode(plate_barcode)
  well = plate.find_well_by_name(well_position)
  well.sample = Sample.create(:name => "Sample_#{well_position}_on_plate_#{plate_barcode}", :empty_supplier_sample_name => true)
  well.save!
end
