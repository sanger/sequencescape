# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PolyMetadatum, type: :model do
  subject(:test_metadatum) { build(:poly_metadatum) }

  # Tests for validations
  describe 'validations' do
    let(:request) { create(:request) }

    it 'is valid with valid attributes' do
      expect(test_metadatum).to be_valid
    end

    context 'when checking the key' do
      it 'validates for presence' do
        expect(test_metadatum).to validate_presence_of(:key)
      end

      it 'sets a suitable error message if not present' do
        test_metadatum.key = nil
        test_metadatum.valid?
        expect(test_metadatum.errors.full_messages).to include('Key can\'t be blank')
      end

      it 'validates uniqueness of key, scoped to metadatable_type and metadatable_id, case insensitive' do
        create(:poly_metadatum, key: 'testkey', value: 'testvalue', metadatable: request)
        test_metadatum.key = 'TESTKEY'
        test_metadatum.metadatable = request
        expect(test_metadatum).not_to be_valid
        expect(test_metadatum.errors[:key]).to include('has already been taken')
      end
    end

    context 'when checking the value' do
      it 'validates for presence' do
        expect(test_metadatum).to validate_presence_of(:value)
      end

      it 'sets a suitable error message if not present' do
        test_metadatum.value = nil
        test_metadatum.valid?
        expect(test_metadatum.errors.full_messages).to include('Value can\'t be blank')
      end
    end

    context 'when checking the metadatable' do
      # test for association to the metadatable object
      it { is_expected.to belong_to(:metadatable).required(true) }

      it 'sets a suitable error message if not present' do
        test_metadatum.metadatable = nil
        test_metadatum.valid?
        expect(test_metadatum.errors.full_messages).to include('Metadatable must exist')
      end
    end
  end

  # Tests for #to_h method
  describe '#to_h' do
    it 'returns a hash with key and value' do
      expect(test_metadatum.to_h).to eq({ 'some_key_1' => 'some_value_1' })
    end
  end
end
