require 'rails_helper'

describe WellAttribute do
  let(:well_attribute) { create :well_attribute }

  it 'should not let current_volume to get negative' do
    well_attribute.current_volume = -2
    well_attribute.save
    expect(well_attribute.current_volume).to eq 0.0
    expect(WellAttribute.last.current_volume).to eq 0.0
    well_attribute.update_attributes!(current_volume: 1)
    expect(well_attribute.current_volume).to eq 1.0
    expect(WellAttribute.last.current_volume).to eq 1.0
  end
end
