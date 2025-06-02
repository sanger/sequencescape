# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ElementAvitiSequencingPipeline, type: :model do
  describe '#post_release_batch' do
    let(:pipeline) { create(:element_aviti_sequencing_pipeline) }
    let(:batch) { create(:batch) }
    # let(:asset) { create(:lane_labware) }

    # before do
    #   batch.assets << asset
    # end

    it 'calls Messenger with eseq_flowcell root' do
      expect(Messenger).to receive(:create!).with(
        hash_including(target: batch, template: 'FlowcellIo', root: 'eseq_flowcell')
      )

      pipeline.post_release_batch(batch, create(:user))
    end
  end
end
