require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe Request::Traction::GridIon do
  subject { build :request_traction_grid_ion, asset: well, request_metadata_attributes: metadata, order: order, submission: submission, request_type: request_type }
  let(:order) { build(:order, submission: submission, assets: [well], request_types: [request_type.id]) }
  let(:request_type) { create :well_request_type }
  let(:submission) { build(:submission) }
  let(:well) { create :well }

  context 'with valid metadata' do
    let(:metadata) do
      { library_type: 'Rapid', file_type: 'FASTQ' }
    end
    it { is_expected.to be_valid }

    it 'saves the metadata' do
      subject.save!
      expect(subject.request_metadata.library_type).to eq('Rapid')
      expect(subject.request_metadata.file_type).to eq('FASTQ')
    end

    it 'registers a submission callback' do
      subject.save!
      expect(submission.callbacks.count).to eq(1)
      submission.process_callbacks!
      expect(subject.reload.work_order).not_to be_nil
    end
  end

  context '::sequencing?' do
    subject { described_class.sequencing? }
    it { is_expected.to be true }
  end
end
