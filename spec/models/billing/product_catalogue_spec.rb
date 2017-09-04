require 'rails_helper'

describe Billing::ProductCatalogue do
  let!(:product_catalogue) {Billing::ProductCatalogue.create(name: 'standard')}

  it 'should have a unique name' do
    expect(product_catalogue.name).to eq 'standard'
    expect(product_catalogue.valid?).to be true
    product_catalogue_with_nonunique_name = Billing::ProductCatalogue.new(name: 'standard')
    expect(product_catalogue_with_nonunique_name.valid?).to be false
  end


end
