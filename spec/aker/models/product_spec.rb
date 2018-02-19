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

  it 'is not valid without a catalogue' do
    expect(build(:aker_product, catalogue: nil)).to_not be_valid
  end

  it 'is not valid without the requested biomaterial type' do
    expect(build(:aker_product, requested_biomaterial_type: nil)).to_not be_valid
  end

  it 'is not valid without the product class' do
    expect(build(:aker_product, product_class: nil)).to_not be_valid
  end

  it 'any update will bump the product version' do
    product = create(:aker_product)
    expect(product.product_version).to eq(1)
    product.update_attributes(availability: false)
    expect(product.availability).to be_falsey
    expect(product.product_version).to eq(2)
  end

  it 'json contains stages' do
    product = create(:aker_product)
    create_list(:aker_product_process, 3, product: product)
    json = product.as_json
    expect(json[:processes].all? { |p| p[:stage].present? }).to be_truthy
  end
end
