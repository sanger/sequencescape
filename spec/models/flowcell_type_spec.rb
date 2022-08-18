# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcellType do
  subject { described_class.new(requested_flowcell_type: requested_flowcell_type) }

  context 'without a requested_flowcell_type' do
    let(:requested_flowcell_type) { '' }

    it { is_expected.not_to be_valid }
  end

  context 'with a unique requested_flowcell_type' do
    let(:requested_flowcell_type) { 'Unique' }

    it { is_expected.to be_valid }
  end

  context 'with a shared requested_flowcell_type' do
    before { create :flowcell_type, requested_flowcell_type: 'Shared' }

    let(:requested_flowcell_type) { 'Shared' }

    it { is_expected.not_to be_valid }
  end

  context 'with a shared requested_flowcell_type (case-insensitive)' do
    before { create :flowcell_type, requested_flowcell_type: 'Shared' }

    let(:requested_flowcell_type) { 'shared' }

    it { is_expected.not_to be_valid }
  end
end
