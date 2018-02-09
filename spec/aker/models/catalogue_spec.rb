require 'rails_helper'

RSpec.describe Aker::Catalogue, type: :model, aker: true do
  it 'is not valid without a pipeline name' do
    expect(build(:aker_catalogue, pipeline: nil)).to_not be_valid
  end

  it 'is not valid without a lims_id' do
    expect(build(:aker_catalogue, lims_id: nil)).to_not be_valid
  end

  it 'can have many products' do
    catalogue = create(:aker_catalogue)
    create_list(:aker_product, 3, catalogue: catalogue)
    expect(catalogue.products.count).to eq(3)
  end
end
