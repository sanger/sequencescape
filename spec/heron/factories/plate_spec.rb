# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Plate, type: :model, heron: true do
  let(:purpose) do
    create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96')
  end
  let(:study) do
    create(:study)
  end
  let(:plate_factory) { described_class.new(params) }
  let(:params) do
    { study: study, plate_purpose: purpose }
  end

  include BarcodeHelper

  before do
    mock_plate_barcode_service
  end

  it 'can build a valid plate factory' do
    expect(plate_factory).to be_valid
  end

  it 'can create a new plate' do
    expect do
      plate_factory.create
    end.to change(Plate, :count).by(1)
  end

  context 'when providing samples information' do
    let!(:sample) { create(:sample) }
    let(:wells_params) do
      {
        'A01' => { phenotype: 'A phenotype' },
        'B01' => { phenotype: 'A phenotype' },
        'C01' => { sample_uuid: sample.uuid }
      }
    end
    let(:params) do
      { study: study, plate_purpose: purpose, wells: wells_params }
    end

    it 'creates the plate' do
      expect do
        plate_factory.create
      end.to change(Plate, :count).by(1)
    end

    it 'creates the new samples' do
      expect { plate_factory.create }.to change(Sample, :count).by(2).and change(Aliquot, :count).by(3)
    end
  end
end
