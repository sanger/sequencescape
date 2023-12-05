# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PolyMetadatum, type: :model do
  subject { build(:poly_metadatum) }

  # Test for validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:metadatable_id).case_insensitive }
  end

  # Test for associations
  describe 'associations' do
    it { is_expected.to belong_to(:metadatable) }
    it { is_expected.to have_many(:poly_metadata) }
  end

  # Test for #to_h method
  describe '#to_h' do
    it 'returns a hash with key and value' do
      poly_metadatum = described_class.new(key: 'test_key', value: 'test_value', metadatable: build(:request))
      expect(poly_metadatum.to_h).to eq({ 'test_key' => 'test_value' })
    end
  end
end
