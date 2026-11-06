# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaTag do
  subject(:ultima_tag) { build(:ultima_tag) }

  describe 'associations' do
    it { is_expected.to belong_to(:tag).required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_uniqueness_of(:tag_id) }
    it { is_expected.to validate_presence_of(:index_barcode_num) }
    it { is_expected.to validate_presence_of(:barcode_plate_well) }

    it 'accepts "Z" followed by four digits' do
      expect(ultima_tag).to allow_values('Z0001', 'Z5048', 'Z9999')
        .for(:index_barcode_num)
    end

    it 'rejects other index barcode nums' do
      expect(ultima_tag).not_to allow_values(
        'Z501', 'Z50011', 'z0001', '0001', 'ZZ001', "Z0001\n"
      ).for(:index_barcode_num)
    end
  end

  describe '#z_index' do
    it 'is the index barcode num' do
      ultima_tag.index_barcode_num = 'Z5005'
      expect(ultima_tag.z_index).to eq('Z5005')
    end
  end
end
