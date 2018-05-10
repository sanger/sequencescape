# frozen_string_literal: true

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

  it 'can have a cv' do
    expect(build(:qc_result).cv).to be_present
  end

  it 'can have an assay type' do
    expect(build(:qc_result).assay_type).to be_present
  end

  it 'can have an assay version' do
    expect(build(:qc_result).assay_version).to be_present
  end
end
