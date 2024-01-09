# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PolyMetadatum, type: :model do
  subject(:test_metadatum) { build(:poly_metadatum) }

  # Tests for validations
  describe 'validations' do
    it 'requires a key' do
      expect(test_metadatum).to validate_presence_of(:key)
    end

    it 'requires a value' do
      expect(test_metadatum).to validate_presence_of(:value)
    end

    it 'key must be unique' do
      expect(test_metadatum).to validate_uniqueness_of(:key).scoped_to(:metadatable_id).case_insensitive
    end

    context 'when creating a new poly_metadatum' do
      it 'is valid with valid attributes' do
        expect(test_metadatum).to be_valid
      end

      it 'is invalid without a key' do
        test_metadatum.key = nil
        expect(test_metadatum).not_to be_valid
        expect(test_metadatum.errors.full_messages).to include('Key can\'t be blank')
      end

      it 'is invalid without a value' do
        test_metadatum.value = nil
        expect(test_metadatum).not_to be_valid
        expect(test_metadatum.errors.full_messages).to include('Value can\'t be blank')
      end

      it 'is invalid without a metadatable' do
        test_metadatum.metadatable = nil
        expect(test_metadatum).not_to be_valid
        expect(test_metadatum.errors.full_messages).to include('Metadatable must exist')
      end
    end
  end

  # Tests for associations
  describe 'associations' do
    it 'belongs to metadatable' do
      expect(test_metadatum).to belong_to(:metadatable).required
    end
  end

  # Tests for #to_h method
  describe '#to_h' do
    it 'returns a hash with key and value' do
      expect(test_metadatum.to_h).to eq({ 'some_key_1' => 'some_value_1' })
    end
  end
end
