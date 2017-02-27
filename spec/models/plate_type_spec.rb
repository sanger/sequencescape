require 'rails_helper'

describe PlateType do
  let(:plate_type) { PlateType.new name: 'name', maximum_volume: 100 }
  let(:invalid_plate_type) { PlateType.new }

  it 'should have name and maximum volume' do
    expect(invalid_plate_type.valid?).to be false
    expect(invalid_plate_type.errors.messages.length).to eq 2
    expect(plate_type.valid?).to be true
  end

  it 'knows cherrypickable default type' do
    expect(PlateType.cherrypickable_default_type).to eq 'ABgene_0800'
  end

  it 'knows plate types names and maximum volumes' do
    expect(PlateType.names_and_maximum_volumes).to eq 'ABgene_0765: 800, ABgene_0800: 180, FluidX075: 500, FluidX03: 280'
  end
end
