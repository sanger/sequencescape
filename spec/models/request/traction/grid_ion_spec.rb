# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe Request::Traction::GridIon do
  subject do
    build :request_traction_grid_ion,
          asset: well,
          request_metadata_attributes: metadata,
          order:,
          submission:,
          request_type:,
          state:
  end

  let(:order) { build(:order, submission:, assets: [well], request_types: [request_type.id]) }
  let(:request_type) { create :well_request_type }
  let(:submission) { build(:submission) }
  let(:well) { create :well }
  let(:state) { 'pending' }

  context 'with valid metadata' do
    let(:metadata) { { library_type: 'Rapid', data_type: 'basecalls and raw data' } }

    it { is_expected.to be_valid }

    it 'saves the metadata' do
      subject.save!
      expect(subject.request_metadata.library_type).to eq('Rapid')
      expect(subject.request_metadata.data_type).to eq('basecalls and raw data')
    end

    it 'registers a submission callback' do
      subject.save!
      expect(submission.callbacks.count).to eq(1)
      submission.process_callbacks!
      expect(subject.reload.work_order).not_to be_nil
    end

    context 'with standard states' do
      it { is_expected.to be_valid }
    end

    context 'with custom states' do
      let(:state) { 'custom_external_state' }

      it { is_expected.to be_valid }
    end
  end

  context '::sequencing?' do
    subject { described_class.sequencing? }

    it { is_expected.to be true }
  end
end
