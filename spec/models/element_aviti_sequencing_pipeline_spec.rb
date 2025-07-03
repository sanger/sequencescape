# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ElementAvitiSequencingPipeline, type: :model do
  describe '#post_release_batch' do
    let(:pipeline) { create(:element_aviti_sequencing_pipeline) }
    let(:batch) { create(:batch) }

    it 'calls Messenger with eseq_flowcell root' do
      allow(Messenger).to receive(:create!)
      pipeline.post_release_batch(batch, create(:user))

      expect(Messenger).to have_received(:create!).with(
        hash_including(target: batch, template: 'FlowcellIo', root: 'eseq_flowcell')
      )
    end
  end
end
