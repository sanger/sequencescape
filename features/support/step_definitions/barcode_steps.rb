
Given /^the plate barcode webservice returns "([1-9][0-9]*)"$/ do |barcode|
  FakeBarcodeService.instance.barcode(barcode)
end

Given /^a plate barcode webservice is available and returns "(\d+)"$/ do |barcode|
  step(%Q{the plate barcode webservice returns "#{barcode}"})
end

Given /^the plate barcode webservice returns "([1-9][0-9]*)\.\.([1-9][0-9]*)"$/ do |start, finish|
  (start.to_i..finish.to_i).each { |i| step(%Q{the plate barcode webservice returns "#{i}"}) }
end

Given /^the "([^\"]+)" barcode printer "([^\"]+)" exists$/ do |type_name, name|
  printer_type = BarcodePrinterType.find_by!(name: type_name)
  BarcodePrinter.create!(name: name, barcode_printer_type: printer_type, active: true)
end

Transform /^the last plate$/ do |_|
  Plate.last or raise StandardError, 'There appear to be no plates'
end

Transform /^the last multiplexed library tube$/ do |_|
  MultiplexedLibraryTube.last or raise StandardError, 'There appear to be no multiplexed library tubes'
end

Transform /^the plate "([^\"]+)"$/ do |name|
  Plate.find_by(name: name) or raise StandardError, "Could not find the plate #{name.inspect}"
end

Transform /^the plate with ID (\d+)$/ do |id|
  Plate.find(id)
end

Given /^(the .+) has a barcode of "([^\"]+)"$/ do |barcoded, barcode|
  # Annoyingly this is used for batches, as well as labware
  if barcoded.respond_to?(:primary_barcode)
    bc = SBCF::SangerBarcode.from_machine(barcode).human_barcode
    barcoded.primary_barcode.update(barcode: bc)
  else
    barcoded.update_attributes!(barcode: Barcode.number_to_human(barcode.to_i))
  end
end

Given /^the barcode of the last sample tube is "([^\"]+)"$/ do |barcode|
  bc = SBCF::SangerBarcode.new(prefix: 'NT', number: barcode).human_barcode
  tube = SampleTube.last or raise StandardError, 'There appear to be no sample tubes'
  tube.primary_barcode.update!(barcode: bc)
end

Given /^sample tubes are barcoded sequentially from (\d+)$/ do |initial|
  counter = initial.to_i
  SampleTube.order(:id).each do |asset|
    bc = SBCF::SangerBarcode.new(prefix: 'NT', number: counter).human_barcode
    asset.primary_barcode.update!(barcode: bc)
    counter += 1
  end
end

Given /^library tubes are barcoded sequentially from (\d+)$/ do |initial|
  counter = initial.to_i
  LibraryTube.order(:id).each do |asset|
    bc = SBCF::SangerBarcode.new(prefix: 'NT', number: counter).human_barcode
    asset.primary_barcode.update!(barcode: bc)
    counter += 1
  end
end
