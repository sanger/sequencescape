# frozen_string_literal: true

require 'rails_helper'

describe WellAttribute do
  let(:well_attribute) { create :well_attribute }

  it 'does not let current_volume to get negative' do
    well_attribute.current_volume = -2
    well_attribute.save
    expect(well_attribute.current_volume).to eq 0.0
    expect(described_class.last.current_volume).to eq 0.0
    well_attribute.update!(current_volume: 1)
    expect(well_attribute.current_volume).to eq 1.0
    expect(described_class.last.current_volume).to eq 1.0
  end
end
