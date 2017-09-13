require 'rails_helper'

describe Billing::Product do
  let(:product) { create :billing_product, name: 'name' }

  it 'should have a unique name' do
    expect(product.name).to eq 'name'
    expect(product.valid?).to be true
    product_with_nonunique_name = build :billing_product, name: product.name
    expect(product_with_nonunique_name.valid?).to be false
  end

  it 'can have a differentiator value' do
    product.identifier = 'test'
    expect(product.identifier). to eq 'test'
  end
end
