# frozen_string_literal: true

require 'rails_helper'

describe BarcodePrinter do
  let!(:barcode_printer_plate96) do
    create(:barcode_printer, name: 'test_printer', barcode_printer_type: create(:plate_barcode_printer_type))
  end
  let!(:barcode_printer_type_plate384) do
    BarcodePrinterType.find_by(name: '384 Well Plate') || create(:barcode_printer_type, name: '384 Well Plate')
  end
  let!(:barcode_printer_plate384) { create(:barcode_printer, barcode_printer_type: barcode_printer_type_plate384) }

  it 'knows if it can print on plates with 384 wells' do
    expect(barcode_printer_plate96).not_to be_plate384_printer
    expect(barcode_printer_plate384).to be_plate384_printer
  end

  it 'registers in PMB after create' do
    configatron.register_printers_automatically = true
    allow(RestClient).to receive(:get).with(
      'http://localhost:9292/v2/printers?filter[name]=test_printer',
      content_type: 'application/vnd.api+json',
      accept: 'application/vnd.api+json'
    ).and_return('{"data":[]}')
    allow(RestClient).to receive(:post).with(
      'http://localhost:9292/v2/printers',
      { 'data' => { 'attributes' => { 'name' => 'test_printer', :printer_type => 'squix' } } }.to_json,
      content_type: 'application/vnd.api+json',
      accept: 'application/vnd.api+json'
    ).and_return(201)
    barcode_printer = create(:barcode_printer, name: 'test_printer', printer_type: 'squix')
    expect(barcode_printer).to be_persisted
    configatron.register_printers_automatically = false
  end

  it 'is not valid without a printer type' do
    expect(build(:barcode_printer, printer_type: nil)).not_to be_valid
  end
end
