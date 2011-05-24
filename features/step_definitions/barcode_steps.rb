Then /^I should see barcode "([^"]*)"$/ do |machine_barcode|
  barcode = Barcode.barcode_to_human(machine_barcode)
  Then %Q{I should see "#{barcode}"}
end

Given /^the plate barcode webservice returns "([1-9][0-9]*)"$/ do |barcode|
  FakeBarcodeService.instance.barcode(barcode)
end

Given /^a plate barcode webservice is available and returns "(\d+)"$/ do |barcode|
  Given %Q{the plate barcode webservice returns "#{barcode}"}
end

Given /^the plate barcode webservice returns "([1-9][0-9]*)\.\.([1-9][0-9]*)"$/ do |start, finish|
  (start.to_i..finish.to_i).each { |i| Given %Q{the plate barcode webservice returns "#{i}"} }
end

Given /^the "([^\"]+)" barcode printer "([^\"]+)" exists$/ do |type_name, name|
  printer_type = BarcodePrinterType.find_by_name(type_name) or raise StandardError, "Cannot find barcode printer type #{type_name.inspect}"
  BarcodePrinter.create!(:name => name, :barcode_printer_type => printer_type)
end

Given /^the ([^\"]+) "([^\"]+)" has a barcode of "([^\"]+)"$/ do |model, name, barcode|
  asset = model.gsub(/\s+/, '_').classify.constantize.first(:conditions => { :name => name }) or raise StandardError, "Could not find asset #{name.inspect}"
  asset.update_attributes!(:barcode => Barcode.number_to_human(barcode.to_i))
end

Given /^the barcode of the last sample tube is "([^\"]+)"$/ do |barcode|
  tube = SampleTube.last or raise StandardError, "There appear to be no sample tubes"
  tube.update_attributes!(:barcode => barcode)
end
