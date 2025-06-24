# frozen_string_literal: true

require 'rails_helper'

describe PlateType do
  let(:plate_type) { create(:plate_type) }
  let(:invalid_plate_type) { described_class.new }

  before do
    create(:plate_type, name: 'ABgene_0765', maximum_volume: 800)
    create(:plate_type, name: 'ABgene_0800', maximum_volume: 180)
    create(:plate_type, name: 'FluidX075', maximum_volume: 500)
    create(:plate_type, name: 'FluidX 0.5µl', maximum_volume: 520)
    create(:plate_type, name: 'FluidX03', maximum_volume: 280)
  end

  it 'has name and maximum volume' do
    expect(invalid_plate_type.valid?).to be false
    expect(invalid_plate_type.errors.messages.length).to eq 2
    expect(plate_type.valid?).to be true
  end

  it 'knows cherrypickable default type' do
    expect(described_class.cherrypickable_default_type).to eq 'ABgene_0800'
  end

  it 'knows plate types names and maximum volumes' do
    expect(
      described_class.names_and_maximum_volumes
    ).to eq 'ABgene_0765: 800, ABgene_0800: 180, FluidX075: 500, FluidX 0.5µl: 520, FluidX03: 280'
  end
end
