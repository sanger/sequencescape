# frozen_string_literal: true

# Given /^the plate barcode webservice returns "([1-9][0-9]*)"$/ do |barcode|
#  FakeBarcodeService.instance.barcode(barcode)
# end

Given /^the plate barcode webservice returns "([\w-]+)"$/ do |barcode|
  FakeBarcodeService.instance.barcode(barcode, 'DN')
end

Given /^the Baracoda barcode service returns "([\w-]+)"$/ do |barcode|
  FakeBarcodeService.instance.barcode(barcode)
end

Given(
  /^the Baracoda children barcode service for parent barcode "([\w-]+)" returns (\d+) barcodes?$/
) { |parent_barcode, count| FakeBarcodeService.instance.mock_child_barcodes(parent_barcode, count) }

# Given /^a plate barcode webservice is available and returns "(\d+)"$/ do |barcode|
#  step("the plate barcode webservice returns \"#{barcode}\"")
# end

Given /^a plate barcode webservice is available and returns "([\w-]+)"$/ do |barcode|
  step("the Baracoda barcode service returns \"#{barcode}\"")
  # step("the plate barcode webservice returns \"#{barcode}\"")
end

Given /^the plate barcode webservice returns "([1-9][0-9]*)\.\.([1-9][0-9]*)"$/ do |start, finish|
  (start.to_i..finish.to_i).each { |i| step("the plate barcode webservice returns \"#{i}\"") }
end

Given /^the "([^"]+)" barcode printer "([^"]+)" exists$/ do |type_name, name|
  printer_type = BarcodePrinterType.find_by!(name: type_name)
  BarcodePrinter.create!(name: name, barcode_printer_type: printer_type, active: true)
end

Given '{asset_id} has a barcode of {string}' do |barcoded, barcode|
  bc = SBCF::SangerBarcode.from_machine(barcode).human_barcode
  barcoded.primary_barcode.update(barcode: bc, format: :sanger_code39)
end

Given '{asset_name} has a barcode of {string}' do |barcoded, barcode|
  bc = SBCF::SangerBarcode.from_machine(barcode).human_barcode
  barcoded.primary_barcode.update(barcode: bc, format: :sanger_code39)
end

Given '{batch} has a barcode of {string}' do |barcoded, barcode|
  barcoded.update!(barcode: Barcode.number_to_human(barcode.to_i))
end

Given /^the barcode of the last sample tube is "([^"]+)"$/ do |barcode|
  bc = SBCF::SangerBarcode.new(prefix: 'NT', number: barcode).human_barcode
  tube = SampleTube.last or raise StandardError, 'There appear to be no sample tubes'
  tube.primary_barcode.update!(barcode: bc, format: :sanger_code39)
end

Given /^sample tubes are barcoded sequentially from (\d+)$/ do |initial|
  SampleTube
    .order(:id)
    .each_with_index do |asset, index|
      bc = SBCF::SangerBarcode.new(prefix: 'NT', number: index + initial).human_barcode
      Barcode.find_by(barcode: bc)&.update(barcode: "XX#{index + initial}")
      asset.primary_barcode.update!(barcode: bc)
    end
end

Given /^library tubes are barcoded sequentially from (\d+)$/ do |initial|
  LibraryTube
    .order(:id)
    .each_with_index do |asset, index|
      bc = SBCF::SangerBarcode.new(prefix: 'NT', number: index + initial).human_barcode
      Barcode.find_by(barcode: bc)&.update(barcode: "XX#{index + initial}")
      asset.primary_barcode.update!(barcode: bc)
    end
end
