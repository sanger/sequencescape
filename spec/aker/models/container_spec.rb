require 'rails_helper'

RSpec.describe Aker::Container, type: :model, aker: true do
  it 'is not valid without a barcode' do
    expect(build(:container, barcode: nil)).to_not be_valid
  end

  it 'is not valid without a unique barcode' do
    container = create(:container)
    expect(build(:container, barcode: container.barcode)).to_not be_valid
  end
end
