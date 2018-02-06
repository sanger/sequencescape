require 'rails_helper'

RSpec.describe Aker::Product, type: :model, aker: true do
  it 'is not valid without a name' do
    expect(build(:aker_product, name: nil)).to_not be_valid
  end

  it 'is not valid without a unique name' do
    product = create(:aker_product)
    expect(build(:aker_product, name: product.name)).to_not be_valid
  end

  it 'is not valid without a description' do
    expect(build(:aker_product, description: nil)).to_not be_valid
  end

  it 'can have many processes' do
    product = create(:aker_product)
    create_list(:aker_product_process, 3, product: product)
    expect(product.processes.count).to eq(3)
  end
end
