require 'rails_helper'

RSpec.describe QcResult, type: :model, qc_result: true do
  
  it 'is not valid without a key' do
    expect(build(:qc_result, key: nil)).to_not be_valid
  end

  it 'is not valid without a value' do
    expect(build(:qc_result, value: nil)).to_not be_valid
  end

  it 'is not valid without units' do
    expect(build(:qc_result, units: nil)).to_not be_valid
  end

  it 'must have an asset' do
    expect(build(:qc_result, asset: nil)).to_not be_valid
  end
end
