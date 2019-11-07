# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Factories::Container, type: :model, aker: true do
  include BarcodeHelper
  before do
    mock_plate_barcode_service
    build(:sample_tube_purpose, name: 'Standard sample').save
  end

  let(:json) do
    file = File.read(File.join('spec', 'data', 'aker', 'job.json'))
    JSON.parse(file).with_indifferent_access
  end
  let(:material) do
    json[:job][:materials].first
  end
  let(:params) do
    json[:job][:container]
  end

  it 'is valid with barcode and address' do
    container = described_class.new(params.merge(address: material[:address]))
    expect(container).to be_valid
    expect(container.barcode).to eq(params[:barcode])
    expect(container.address).to eq(material[:address])
  end

  it 'must have a barcode' do
    container = described_class.new(params.except(:barcode))
    expect(container).not_to be_valid
  end

  describe '#create' do
    it 'persists the container if it is valid' do
      container = described_class.create(params)
      expect(container).to be_present
      expect(Aker::Container.find_by(barcode: container.barcode)).to be_present

      container = described_class.create(params.except(:barcode))
      expect(container).to be_nil
    end

    it 'finds the container if it already exists' do
      ar_container = Aker::Container.create(params)
      container = described_class.create(params)

      expect(container).to eq(ar_container)
    end

    it 'creates a plate when the container refers to a well in a plate' do
      described_class.create(params.merge(address: 'A:1'))
      asset = Labware.with_barcode(params[:barcode]).first
      expect(asset.is_a?(Plate)).to eq(true)
    end

    it 'creates a tube when the container address is empty' do
      described_class.create(params)
      asset = Labware.with_barcode(params[:barcode]).first
      expect(asset.is_a?(Tube)).to eq(true)
    end

    it 'creates a tube when the container address is a number' do
      described_class.create(params.merge(address: '1'))
      asset = Labware.with_barcode(params[:barcode]).first
      expect(asset.is_a?(Tube)).to eq(true)
    end

    it 'reuses an already created asset when the container already exists' do
      tube = create(:tube)
      tube.aker_barcode = params[:barcode]
      tube.save!
      container = described_class.create(params)
      expect(container.asset).to eq(tube.receptacle)
    end
  end

  it '#as_json returns the correct attributes' do
    container = described_class.new(params)
    ar_container = container.create
    expect(container.as_json).to eq(ar_container.as_json)
  end
end
