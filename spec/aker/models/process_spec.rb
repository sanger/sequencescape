require 'rails_helper'

RSpec.describe Aker::Process, type: :model, aker: true do
  it 'is not valid without a name' do
    expect(build(:aker_process, name: nil)).to_not be_valid
  end

  it 'is not valid without a unique name' do
    process = create(:aker_process)
    expect(build(:aker_process, name: process.name)).to_not be_valid
  end

  it 'is not valid without a turnaround time' do
    expect(build(:aker_process, tat: nil)).to_not be_valid
  end

  it 'can have many products' do
    process = create(:aker_process)
    create_list(:aker_product_process, 3, process: process)
    expect(process.products.count).to eq(3)
  end

  it 'can have many process module pairings' do
    process_with_pairings = create(:aker_process_with_process_module_pairings, number_of_pairs: 5)
    expect(process_with_pairings.process_module_pairings.count).to eq(5)
  end
end
