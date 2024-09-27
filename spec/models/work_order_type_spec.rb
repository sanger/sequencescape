# frozen_string_literal: true

require 'rails_helper'

describe WorkOrderType do
  subject { build(:work_order_type, name:) }

  context 'with a name' do
    let(:name) { 'test_order' }

    context 'which doesn\'t clash' do
      it { is_expected.to be_valid }
    end

    context 'which already exists' do
      before { create(:work_order_type, name:) }

      it { is_expected.not_to be_valid }
    end
  end

  context 'without an name' do
    let(:name) { nil }

    it { is_expected.not_to be_valid }
  end

  context 'with a name with spaces' do
    let(:name) { 'invalid name' }

    it { is_expected.not_to be_valid }
  end

  context 'with a name with capitals' do
    let(:name) { 'Invalid_name' }

    it { is_expected.not_to be_valid }
  end

  context 'with a name with symbols' do
    let(:name) { 'Invalid@name' }

    it { is_expected.not_to be_valid }
  end
end
