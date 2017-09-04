require 'rails_helper'

describe Billing::Product do
  let!(:product_catalogue) {Billing::ProductCatalogue.create(name: 'standard')}
  let(:product) { Billing::Product.create(name: 'name', product_catalogue: product_catalogue) }

  it 'should have a unique name' do
    expect(product.name).to eq 'name'
    expect(product.valid?).to be true
    product_with_nonunique_name = Billing::Product.new(name: 'name', product_catalogue: product_catalogue)
    expect(product_with_nonunique_name.valid?).to be false
  end

  it 'can have a differentiator value' do
    expect(product.differentiator_value). to eq nil
  end

end
