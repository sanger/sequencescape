# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportFail, type: :model do
  let!(:user) { create(:user, swipecard_code: '12345') }
  let(:plate_1) { create(:plate) }
  let(:plate_2) { create(:plate) }

  it 'records an event' do
    report_fail = described_class.new('12345', '1', [plate_1.human_barcode])
    expect(report_fail.save).to be_truthy
    expect(plate_1.events.first.created_by).to eq(user.login)
  end

  it 'scans the labware into the location' do
    report_fail = described_class.new('12345', '1', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(report_fail.save).to be_truthy
  end

  it 'removes all the missing barcodes' do
    report_fail = described_class.new('12345', '1', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(report_fail.missing_barcodes).to be_empty
  end

  it 'detects all the missing barcodes' do
    report_fail =
      described_class.new('12345', '1', [plate_1.human_barcode, plate_2.machine_barcode, '11111111111111111'])
    expect(report_fail.missing_barcodes).to eq(['11111111111111111'])
  end

  it 'scans the labware into the location if the labware is not in ss' do
    report_fail = described_class.new('12345', 'labwhere_location', %w[1 11111111111111])
    expect(report_fail.save).to be_truthy
  end

  it 'does not scan the labware into the location if no user supplied' do
    report_fail = described_class.new('', '1', [plate_1.human_barcode, plate_2.machine_barcode])
    expect(report_fail.save).to be_falsey
    expect(report_fail.errors).not_to be_empty
  end

  it 'does not scan the labware into the location if no barcodes scanned' do
    report_fail = described_class.new('12345', 'labwhere_location', [])
    expect(report_fail.save).to be_falsey
    expect(report_fail.errors).not_to be_empty
  end
end
