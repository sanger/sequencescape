# frozen_string_literal: true

require 'rails_helper'

describe BarcodePrinter do

  let!(:barcode_printer_plate_96 ) { create(:barcode_printer, name: 'test_printer', barcode_printer_type: create(:plate_barcode_printer_type)) }
  let!(:barcode_printer_type_plate_384) { BarcodePrinterType.find_by(name: '384 Well Plate') || create(:barcode_printer_type, name: '384 Well Plate') }
  let!(:barcode_printer_plate_384 ) { create(:barcode_printer, barcode_printer_type: barcode_printer_type_plate_384) }

  it 'should know if it can print on plates with 384 wells' do
    expect(barcode_printer_plate_96.plate384_printer?).to be_falsey
    expect(barcode_printer_plate_384.plate384_printer?).to be_truthy
  end

  it 'should register in PMB after create' do
    configatron.register_printers_automatically = true
    allow(RestClient).to receive(:get).with('http://localhost:9292/v2/printers?filter[name]=test_printer', content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json').and_return('{"data":[]}')
    allow(RestClient).to receive(:post).with('http://localhost:9292/v2/printers', { 'data' => { 'attributes' => { 'name' => 'test_printer' } } }.to_json, content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json').and_return(201)
    barcode_printer = create(:barcode_printer, name: 'test_printer')
    expect(barcode_printer).to be_persisted
    configatron.register_printers_automatically = false
  end

  it 'should not be valid without a printer type' do
    expect(build(:barcode_printer, printer_type: nil)).to_not be_valid
  end

end
