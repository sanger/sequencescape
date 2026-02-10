# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SamplesHelper, type: :helper do
  subject { helper.save_text(sample) }

  let(:sample) { create(:sample) }

  before do
    allow(helper).to receive(:accessioning_enabled?).and_return(accessioning_enabled)
    allow(helper).to receive(:permitted_to_accession?).with(sample).and_return(permitted)
    allow(sample).to receive(:should_be_accessioned?).and_return(should_be_accessioned)
  end

  context 'when accessioning is enabled, sample should be accessioned, and user is permitted' do
    let(:accessioning_enabled) { true }
    let(:should_be_accessioned) { true }
    let(:permitted) { true }

    it { is_expected.to eq('Save and Accession') }
  end

  context 'when accessioning is disabled' do
    let(:accessioning_enabled) { false }
    let(:should_be_accessioned) { true }
    let(:permitted) { true }

    it { is_expected.to eq('Save Sample') }
  end

  context 'when sample should not be accessioned' do
    let(:accessioning_enabled) { true }
    let(:should_be_accessioned) { false }
    let(:permitted) { true }

    it { is_expected.to eq('Save Sample') }
  end

  context 'when user is not permitted to accession' do
    let(:accessioning_enabled) { true }
    let(:should_be_accessioned) { true }
    let(:permitted) { false }

    it { is_expected.to eq('Save Sample') }
  end
end
