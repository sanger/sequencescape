# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aker::Container, type: :model, aker: true do
  it 'is not valid without a barcode' do
    expect(build(:container, barcode: nil)).not_to be_valid
  end

  it 'is not valid without a unique barcode' do
    container = create(:container)
    expect(build(:container, barcode: container.barcode)).not_to be_valid
  end

  it '#as_json returns correct attributes' do
    container = create(:container_with_address)
    expect(container.as_json).to eq('barcode': container.barcode, 'address': container.address)

    container = create(:container)
    expect(container.as_json).to eq('barcode': container.barcode)
  end

  context 'when updating a container' do
    let(:container) { create(:container_with_address) }

    it 'is not valid if the update has different data' do
      container.update(barcode: 'NOT GOOD ONE', address: 'NOT GOOD ONE')
      expect(container).not_to be_valid
    end

    it 'is valid if the updated data is equal to the contents of the database' do
      container.update(barcode: container.barcode, address: container.address)
      expect(container).to be_valid
    end
  end
end
