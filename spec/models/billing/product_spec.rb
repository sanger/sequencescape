# frozen_string_literal: true

require 'rails_helper'

describe Billing::Product, billing: true do
  let(:product) { create :billing_product, name: 'name' }

  it 'has a unique name' do
    expect(product.name).to eq 'name'
    expect(product.valid?).to be true
    product_with_nonunique_name = build :billing_product, name: product.name
    expect(product_with_nonunique_name.valid?).to be false
  end

  it 'can have an identifier' do
    product.identifier = 'test'
    expect(product.identifier).to eq 'test'
  end

  it 'has a particular category' do
    expect(product.category).to eq 'sequencing'
    product.category = 'library_creation'
    expect(product.category).to eq 'library_creation'
    expect { product.category = 'wrong_category' }.to raise_error ArgumentError
  end
end
