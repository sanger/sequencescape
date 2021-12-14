# frozen_string_literal: true

require 'rails_helper'

# Test for module to provide support to create a compound sample during the
# sequencing request start from all the samples at source of the request
RSpec.describe 'Request::SampleCompoundAliquotTransfer' do
  let(:samples) { create_list :sample, 2 }
  let(:study) { create :study, samples: samples }
  let(:project) { create :project }
  let(:destination) { create :receptacle }
  let(:source) { create :receptacle, aliquots: [aliquot1, aliquot2] }
  let(:library_tube) { create :library_tube, receptacles: [source] }
  let(:sequencing_request) { create(:sequencing_request, asset: source, target_asset: destination) }
  let(:tags) { create_list :tag, 3 }

  describe '#compound_samples_needed?' do
    context 'when number of aliquots is 1' do
      let(:aliquot1) { create :aliquot, sample: samples[0], tag_id: 1, tag_depth: 1, project: project }
      let(:source) { create :receptacle, aliquots: [aliquot1] }

      it 'returns false' do
        expect(sequencing_request).not_to be_compound_samples_needed
      end
    end

    context 'when there is no tag clash, using tags 1 and 2' do
      let(:aliquot1) { create :aliquot, sample: samples[0], tag_id: tags[0].id, tag2_id: tags[1].id, project: project }
      let(:aliquot2) { create :aliquot, sample: samples[1], tag_id: tags[0].id, tag2_id: tags[2].id, project: project }

      it 'returns false' do
        expect(sequencing_request).not_to be_compound_samples_needed
      end
    end

    context 'when there is a tag clash, using tags 1 and 2' do
      let(:aliquot1) do
        create :aliquot, sample: samples[0], tag_id: tags[0].id, tag2_id: tags[1].id, tag_depth: 1, project: project
      end
      let(:aliquot2) do
        create :aliquot, sample: samples[1], tag_id: tags[0].id, tag2_id: tags[1].id, tag_depth: 2, project: project
      end

      it 'returns true' do
        expect(sequencing_request).to be_compound_samples_needed
      end
    end
  end

  describe '#transfer_aliquots_into_compound_sample_aliquots' do
    let(:aliquot1) do
      create :aliquot,
             sample: samples[0],
             tag_id: tags[0].id,
             tag2_id: tags[1].id,
             tag_depth: 1,
             study: study,
             project: project,
             library_type: 'Standard',
             library_id: 54
    end
    let(:aliquot2) do
      create :aliquot,
             sample: samples[1],
             tag_id: tags[0].id,
             tag2_id: tags[1].id,
             tag_depth: 2,
             study: study,
             project: project,
             library_type: 'Standard',
             library_id: 54
    end

    it 'creates a compound sample and transfers an aliquot of it' do
      expect(sequencing_request.target_asset.aliquots.count).to eq(0)
      sequencing_request.transfer_aliquots_into_compound_sample_aliquots
      expect(sequencing_request.target_asset.aliquots.count).to eq(1)
      expect(sequencing_request.target_asset.aliquots.first.library_type).to eq('Standard')
      expect(sequencing_request.target_asset.aliquots.first.study).to eq(study)
      expect(sequencing_request.target_asset.aliquots.first.project).to eq(project)
      expect(sequencing_request.target_asset.aliquots.first.library_id).to eq(54)
      expect(sequencing_request.target_asset.samples.first.component_samples.order(:id)).to eq(samples.sort)
    end

    # How the library_id should be set if the source aliquots have different library_ids is not defined
    # Therefore, set it to nil for now, until we have a real requirement
    context 'with conflicting library_ids' do
      before { aliquot1.update!(library_id: 82) }

      it 'creates a compound sample with a blank library id' do
        sequencing_request.transfer_aliquots_into_compound_sample_aliquots
        expect(sequencing_request.target_asset.aliquots.count).to eq(1)
        expect(sequencing_request.target_asset.aliquots.first.library_id).to be_nil
      end
    end
  end
end
