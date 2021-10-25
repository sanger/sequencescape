# frozen_string_literal: true

require 'rails_helper'

# Test for module to provide support to create a compound sample during the
# sequencing request start from all the samples at source of the request
RSpec.describe 'Request::SampleCompoundAliquotTransfer' do

  let(:samples) { create_list :sample, 2 }
  let(:study) { create :study, samples: samples }
  let(:destination) { create :receptacle }
  let(:source) { create :receptacle, aliquots: [aliquot1, aliquot2] }
  let(:library_tube) { create :library_tube, receptacles: [source] }
  let(:sequencing_request) { create(:sequencing_request, asset: source, target_asset: destination) }

  describe '#compound_samples_needed?' do
    context 'when tag_depth not defined' do
      let(:aliquot1) { create :aliquot, sample: samples[0], tag_id: 1 }
      let(:aliquot2) { create :aliquot, sample: samples[1], tag_id: 2 }  

      it 'returns false' do
        expect(sequencing_request).not_to be_compound_samples_needed
      end
    end

    context 'when tag_depth defined' do
      let(:aliquot1) { create :aliquot, sample: samples[0], tag_depth: 1 }
      let(:aliquot2) { create :aliquot, sample: samples[1], tag_depth: 2 }  

      it 'returns true' do
        expect(sequencing_request).to be_compound_samples_needed
      end
    end
  end

  describe '#transfer_aliquots_into_compound_sample_aliquot' do
    let(:aliquot1) { create :aliquot, sample: samples[0], tag_depth: 1 }
    let(:aliquot2) { create :aliquot, sample: samples[1], tag_depth: 2 }    

    it 'creates a compound sample and transfers an aliquot of it' do
      expect(sequencing_request.target_asset.aliquots.count).to eq(0)
      sequencing_request.transfer_aliquots_into_compound_sample_aliquot
      expect(sequencing_request.target_asset.aliquots.count).to eq(1)
      expect(
        sequencing_request.target_asset.samples.first.component_samples.order(:id)
      ).to eq(samples.sort)
    end
  end
end
