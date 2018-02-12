require 'rails_helper'

RSpec.describe Aker::ProductProcess, type: :model, aker: true do
  it 'is not valid without a product' do
    expect(build(:aker_product_process, product: nil)).to_not be_valid
  end

  it 'is not valid without a process' do
    expect(build(:aker_product_process, process: nil)).to_not be_valid
  end

  it 'is not valid without a stage' do
    expect(build(:aker_product_process, stage: nil)).to_not be_valid
  end
end
