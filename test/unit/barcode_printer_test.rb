require 'test_helper'

class BarcodePrinterTest < ActiveSupport::TestCase
  attr_reader :barcode_printer, :printer_for_384_wells_plate

  def setup
    @barcode_printer = create :barcode_printer, name: 'test_printer'
    @printer_for_384_wells_plate = create :barcode_printer, barcode_printer_type_id: 3
  end

  test 'should know if it can print on plates with 384 wells' do
    refute barcode_printer.plate384_printer?
    assert printer_for_384_wells_plate.plate384_printer?
  end

  test 'should register printer in PMB after create' do
    configatron.register_printers_automatically = true
    RestClient.expects(:get)
              .with('http://localhost:9292/v1/printers?filter[name]=test_printer',
                content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json')
              .returns('{"data":[]}')
    RestClient.expects(:post)
              .with('http://localhost:9292/v1/printers',
                        { 'data' => { 'attributes' => { 'name' => 'test_printer' } } }.to_json,
                        content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json')
              .returns(201)
    create :barcode_printer, name: 'test_printer'
    configatron.register_printers_automatically = false
  end
end
