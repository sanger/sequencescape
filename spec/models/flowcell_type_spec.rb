# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcellType do
  subject { described_class.new(name:) }

  context 'without a name' do
    let(:name) { '' }

    it { is_expected.not_to be_valid }
  end

  context 'with a unique name' do
    let(:name) { 'Unique' }

    it { is_expected.to be_valid }
  end

  context 'with a shared name' do
    before { create :flowcell_type, name: 'Shared' }

    let(:name) { 'Shared' }

    it { is_expected.not_to be_valid }
  end

  context 'with a shared name (case-insensitive)' do
    before { create :flowcell_type, name: 'Shared' }

    let(:name) { 'shared' }

    it { is_expected.not_to be_valid }
  end
end
