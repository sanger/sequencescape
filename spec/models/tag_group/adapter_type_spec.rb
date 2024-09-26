# frozen_string_literal: true

require 'rails_helper'

describe TagGroup::AdapterType do
  subject(:adapter_type) { build(:adapter_type, name:) }

  context 'when it has a unique name' do
    let(:name) { 'name' }

    it { is_expected.to be_valid }

    describe '#destroy' do
      subject { adapter_type.destroy }

      context 'when it is unused' do
        it { is_expected.to be_destroyed }
      end

      context 'when it is in use' do
        before { create(:tag_group, adapter_type:) }

        it { is_expected.to be false }
      end
    end
  end

  context 'when it is named Unspecified' do
    let(:name) { 'Unspecified' }

    it { is_expected.not_to be_valid }
  end

  # We should be case insensitive in this check.
  context 'when it is named unspecified' do
    let(:name) { 'unspecified' }

    it { is_expected.not_to be_valid }
  end

  context 'when it is nameless' do
    let(:name) { '' }

    it { is_expected.not_to be_valid }
  end

  context 'when its name is already in use' do
    before { create(:adapter_type, name: 'name') }

    let(:name) { 'name' }

    it { is_expected.not_to be_valid }
  end
end
