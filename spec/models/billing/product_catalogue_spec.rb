require 'rails_helper'

describe Billing::ProductCatalogue do
  let!(:product_catalogue) { create :billing_product_catalogue, name: 'standard' }

  it 'should have a unique name' do
    expect(product_catalogue.name).to eq 'standard'
    expect(product_catalogue.valid?).to be true
    product_catalogue_with_nonunique_name = build :billing_product_catalogue, name: 'standard'
    expect(product_catalogue_with_nonunique_name.valid?).to be false
  end

  it 'should know if it is a single product catalogue' do
    create :billing_product, billing_product_catalogue: product_catalogue
    product_catalogue.reload
    expect(product_catalogue.single_product?).to eq true
    create :billing_product, billing_product_catalogue: product_catalogue
    product_catalogue.reload
    expect(product_catalogue.single_product?).to eq false
  end

  it 'finds the right product for a request' do
    product_catalogue.differentiator = :read_length
    request = create :sequencing_request
    request.request_metadata.update_attributes(read_length: 150)
    create :billing_product, billing_product_catalogue: product_catalogue, differentiator_value: 100
    product = create :billing_product, billing_product_catalogue: product_catalogue, differentiator_value: 150
    expect(product_catalogue.find_product_for_request(request)).to eq product
  end
end
