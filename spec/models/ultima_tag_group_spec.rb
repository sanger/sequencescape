# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaTagGroup do
  subject(:ultima_tag_group) { build(:ultima_tag_group) }

  describe 'associations' do
    it { is_expected.to belong_to(:tag_group).required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_uniqueness_of(:tag_group_id) }

    it do
      expect(ultima_tag_group).to validate_numericality_of(:barcode_plate_num)
        .only_integer.is_greater_than(0)
    end
  end
end
