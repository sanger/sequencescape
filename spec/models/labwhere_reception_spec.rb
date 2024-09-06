# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwhereReception do
  let!(:user) { create(:user, swipecard_code: '12345') }
  let(:plate_1) { create(:plate) }
  let(:plate_2) { create(:plate) }
  let(:location) { 'DN123456' }

  it 'records an event' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(
      instance_double(LabWhereClient::Scan, valid?: true, errors: [])
    )
    reception = described_class.new('12345', location, [plate_1.human_barcode])
    expect(reception.save).to be_truthy
    expect(plate_1.events.first.created_by).to eq(user.login)
  end

  it 'scans the labware into the location' do
    allow(LabWhereClient::Scan).to receive(:create).with(
      location_barcode: 'labwhere_location',
      user_code: '12345',
      labware_barcodes: [plate_1.human_barcode, plate_2.machine_barcode]
    ).and_return(instance_double(LabWhereClient::Scan, valid?: true, errors: []))
    labwhere_reception =
      described_class.new('12345', 'labwhere_location', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(labwhere_reception.save).to be_truthy
  end

  it 'removes all the missing barcodes' do
    labwhere_reception =
      described_class.new('12345', 'labwhere_location', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(labwhere_reception.missing_barcodes).to be_empty
  end

  it 'detects all the missing barcodes' do
    labwhere_reception =
      described_class.new(
        '12345',
        'labwhere_location',
        [plate_1.human_barcode, plate_2.machine_barcode, '11111111111111111']
      )
    expect(labwhere_reception.missing_barcodes).to eq(['11111111111111111'])
  end

  it 'scans the labware into the location if the labware is not in ss' do
    allow(LabWhereClient::Scan).to receive(:create).with(
      location_barcode: 'labwhere_location',
      user_code: '12345',
      labware_barcodes: %w[1 11111111111111]
    ).and_return(instance_double(LabWhereClient::Scan, valid?: true, errors: []))
    labwhere_reception = described_class.new('12345', 'labwhere_location', %w[1 11111111111111])
    expect(labwhere_reception.save).to be_truthy
  end

  it 'does not scan the labware into the location if no user supplied' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(
      instance_double(LabWhereClient::Scan, valid?: true, errors: [])
    )
    labwhere_reception = described_class.new('', 'labwhere_location', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).not_to be_empty
  end

  it 'does not scan the labware into the location if no barcodes scanned' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(
      instance_double(LabWhereClient::Scan, valid?: true, errors: [])
    )
    labwhere_reception = described_class.new('12345', 'labwhere_location', [])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).not_to be_empty
  end

  it 'does not scan the labware into the location if scan was not created' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(
      instance_double(LabWhereClient::Scan, valid?: false, errors: [])
    )
    labwhere_reception =
      described_class.new('12345', 'labwhere_location', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(labwhere_reception.save).to be_falsey
  end

  it 'does not scan the labware into the location if LabwhereException was raised' do
    allow(LabWhereClient::Scan).to receive(:create).and_raise(LabWhereClient::LabwhereException)
    labwhere_reception =
      described_class.new('12345', 'labwhere_location', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).not_to be_empty
  end

  it 'does not scan the labware into the location if Labwhere returns errors' do
    allow(LabWhereClient::Scan).to receive(:create).and_return(
      instance_double(LabWhereClient::Scan, valid?: false, errors: ['User not recognised', 'Location does not exist'])
    )
    labwhere_reception =
      described_class.new('12345', 'labwhere_location', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(labwhere_reception.save).to be_falsey
    expect(labwhere_reception.errors).not_to be_empty
    expect(labwhere_reception.errors.full_messages.first).to eq(
      ['Labwhere User not recognised', 'Labwhere Location does not exist']
    )
  end
end
