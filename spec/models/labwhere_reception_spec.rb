# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwhereReception do
  MockResponse ||= Struct.new(:valid?, :error)

  let!(:user) { create(:user, swipecard_code: '12345') }
  let(:plate_1) { create(:plate, barcode: 1) }
  let(:plate_2) { create(:plate, barcode: 2) }
  let(:location) { 'DN123456' }

  it 'records an event' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(MockResponse.new(true, ''))
    reception = LabwhereReception.new('12345', location, [plate_1.ean13_barcode])
    expect(reception.save).to be_truthy
    expect(plate_1.events.first.created_by).to eq(user.login)
  end

  it 'scans the labware into the location' do
    allow(LabWhereClient::Scan).to receive(:create).with(location_barcode: 'labwhere_location', user_code: '12345', labware_barcodes: [plate_1.ean13_barcode, plate_2.ean13_barcode]).and_return(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new('12345', 'labwhere_location', [plate_1.ean13_barcode, plate_2.ean13_barcode])
    expect(labwhere_reception.save).to be_truthy
  end

  it 'scans the labware into the location if the labware is not in ss' do
    allow(LabWhereClient::Scan).to receive(:create).with(location_barcode: 'labwhere_location', user_code: '12345', labware_barcodes: ['1', '11111111111111']).and_return(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new('12345', 'labwhere_location', ['1', '11111111111111'])
    expect(labwhere_reception.save).to be_truthy
  end

  it 'does not scan the labware into the location if no user supplied' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new('', 'labwhere_location', [plate_1.ean13_barcode, plate_2.ean13_barcode])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).to_not be_empty
  end

  it 'does not scan the labware into the location if no barcodes scanned' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new('12345', 'labwhere_location', [])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).to_not be_empty
  end

  it 'does not scan the labware into the location if scan was not created' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(MockResponse.new(false, ''))
    labwhere_reception = LabwhereReception.new('12345', 'labwhere_location', [plate_1.ean13_barcode, plate_2.ean13_barcode])
    expect(labwhere_reception.save).to be_falsey
  end

  it 'does not scan the labware into the location if LabwhereException was raised' do
    allow(LabWhereClient::Scan).to receive(:create).and_raise(LabWhereClient::LabwhereException)
    labwhere_reception = LabwhereReception.new('12345', 'labwhere_location', [plate_1.ean13_barcode, plate_2.ean13_barcode])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).to_not be_empty
  end
end
