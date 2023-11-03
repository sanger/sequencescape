# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::TubeRackStatus, :heron, type: :model do
  before { create(:study) }

  let(:params) { { barcode: '0000000001', status: 'validation_failed', messages: ['message 1', 'message 2'] } }

  it 'is valid with all relevant attributes' do
    tube_rack_status = described_class.new(params)
    expect(tube_rack_status).to be_valid
  end

  it 'is not valid without barcode' do
    tube_rack_status = described_class.new(params.except(:barcode))
    expect(tube_rack_status).not_to be_valid
  end

  it 'is not valid without the status' do
    tube_rack_status = described_class.new(params.except(:status))
    expect(tube_rack_status).not_to be_valid
  end

  it 'is not valid without messages' do
    tube_rack_status = described_class.new(params.except(:messages))
    expect(tube_rack_status).not_to be_valid
  end

  describe '#save' do
    it 'returns false if barcode is not present' do
      tube_rack_status = described_class.new(params.except(:barcode))
      expect(tube_rack_status.save).to be_falsy
    end

    it 'returns false if status is not present' do
      tube_rack_status = described_class.new(params.except(:status))
      expect(tube_rack_status.save).to be_falsy
    end

    it 'returns true if it saves correctly' do
      tube_rack_status = described_class.new(params)
      expect(tube_rack_status.save).to be_truthy
    end

    it 'creates the tube_rack_status' do
      tube_rack_status = described_class.new(params)
      expect { tube_rack_status.save }.to change(TubeRackStatus, :count).by(1)
    end
  end
end
