# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Then /^I should see barcode "([^"]*)"$/ do |machine_barcode|
  barcode = Barcode.barcode_to_human(machine_barcode)
  step %Q{I should see "#{barcode}"}
end

Given /^the plate barcode webservice returns "([1-9][0-9]*)"$/ do |barcode|
  FakeBarcodeService.instance.barcode(barcode)
end

Given /^a plate barcode webservice is available and returns "(\d+)"$/ do |barcode|
  step(%Q{the plate barcode webservice returns "#{barcode}"})
end

Given /^the plate barcode printing service will error$/ do
  FakeBarcodeService.instance.push_printing_error
end

Given /^the plate barcode service is available with barcodes "([1-9][0-9]*)\.\.([1-9][0-9]*)"$/ do |start, finish|
  (start.to_i..finish.to_i).each { |i| step(%Q{the plate barcode webservice returns "#{i}"}) }
end

Given /^the plate barcode webservice returns "([1-9][0-9]*)\.\.([1-9][0-9]*)"$/ do |start, finish|
  (start.to_i..finish.to_i).each { |i| step(%Q{the plate barcode webservice returns "#{i}"}) }
end

Given /^the "([^\"]+)" barcode printer "([^\"]+)" exists$/ do |type_name, name|
  printer_type = BarcodePrinterType.find_by(name: type_name) or raise StandardError, "Cannot find barcode printer type #{type_name.inspect}"
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

Given /^(the .+) has a barcode of "([^\"]+)"$/ do |asset, barcode|
  asset.update_attributes!(barcode: Barcode.number_to_human(barcode.to_i))
end

Given /^the barcode of the last sample tube is "([^\"]+)"$/ do |barcode|
  tube = SampleTube.last or raise StandardError, 'There appear to be no sample tubes'
  tube.update_attributes!(barcode: barcode)
end

Given /^sample tubes are barcoded sequentially from (\d+)$/ do |initial|
  counter = initial.to_i
  SampleTube.order(:id).each do |asset|
    asset.update_attributes!(barcode: counter)
    counter += 1
  end
end

Given /^library tubes are barcoded sequentially from (\d+)$/ do |initial|
  counter = initial.to_i
  LibraryTube.order(:id).each do |asset|
    asset.update_attributes!(barcode: counter)
    counter += 1
  end
end
