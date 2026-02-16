# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SamplesHelper, type: :helper do
  describe '#save_text' do
    subject { helper.save_text(sample) }

    let(:sample) { create(:sample) }

    let(:accessioning_enabled) { true }
    let(:should_be_accessioned) { true }
    let(:permitted) { true }

    before do
      allow(helper).to receive(:accessioning_enabled?).and_return(accessioning_enabled)
      allow(helper).to receive(:permitted_to_accession?).with(sample).and_return(permitted)
      allow(sample).to receive(:should_be_accessioned?).and_return(should_be_accessioned)
    end

    context 'when accessioning is enabled, sample should be accessioned, and user is permitted' do
      it { is_expected.to eq('Save and Accession') }
    end

    context 'when accessioning is disabled' do
      let(:accessioning_enabled) { false }

      it { is_expected.to eq('Save Sample') }
    end

    context 'when sample should not be accessioned' do
      let(:should_be_accessioned) { false }

      it { is_expected.to eq('Save Sample') }
    end

    context 'when user is not permitted to accession' do
      let(:permitted) { false }

      it { is_expected.to eq('Save Sample') }
    end
  end

  describe '#samples_not_accessioned' do
    subject { helper.samples_not_accessioned(samples) }

    context 'when all samples are accessioned' do
      let(:samples) { build_list(:accessioned_sample, 3) }

      it { is_expected.to eq('All samples accessioned') }
    end

    context 'when some samples are not accessioned' do
      let(:samples) do
        [
          build(:accessioned_sample),
          build(:sample),
          build(:sample)
        ]
      end

      it { is_expected.to eq('2 samples not accessioned') }

      context 'when only one sample is not accessioned' do
        let(:samples) do
          [
            build(:accessioned_sample),
            build(:accessioned_sample),
            build(:sample)
          ]
        end

        it { is_expected.to eq('1 sample not accessioned') }
      end
    end

    context 'when no samples are accessioned' do
      let(:samples) { build_list(:sample, 3) }

      it { is_expected.to eq('No samples accessioned') }
    end

    context 'when there are no samples' do
      let(:samples) { [] }

      it { is_expected.to eq('No samples accessioned') }
    end
  end
end
