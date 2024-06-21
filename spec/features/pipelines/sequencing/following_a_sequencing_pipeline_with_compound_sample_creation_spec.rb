# frozen_string_literal: true

require 'rails_helper'
require './spec/features/shared_examples/sequencing'

RSpec.describe 'Following a Sequencing Pipeline', :js do
  let(:user) { create :user }
  let(:study1) { create :study }
  let(:project1) { create :project }
  let(:pipeline) { create(:sequencing_pipeline, :with_workflow) }
  let(:spiked_buffer) { create :spiked_buffer, :tube_barcode }
  let(:tag) { create :tag, oligo: 'T' }
  let(:tag2) { create :tag, oligo: 'C' }

  let(:aliquot1) do
    create :aliquot,
           tag_id: tag.id,
           tag2_id: tag2.id,
           tag_depth: 1,
           study: study1,
           project: project1,
           library_type: 'Standard',
           library_id: 54
  end
  let(:aliquot2) do
    create :aliquot,
           tag_id: tag.id,
           tag2_id: tag2.id,
           tag_depth: 2,
           study: study1,
           project: project1,
           library_type: 'Standard',
           library_id: 54
  end

  let(:requests) do
    asset = create :multiplexed_library_tube, :scanned_into_lab, sample_count: 2
    asset.aliquots = [aliquot1, aliquot2]
    asset.reload
    create_list :sequencing_request_with_assets,
                2,
                request_type: pipeline.request_types.first,
                asset: asset,
                target_asset: nil,
                submission: create(:submission)
  end

  before { requests }

  context 'when no compound sample exists with the component samples' do
    it_behaves_like 'a sequencing procedure'
  end

  context 'when a compound sample already exists with the source_aliquot samples' do
    let(:compound_sample) { create(:sample, name: 'compound_sample_1') }

    before do
      compound_sample.update(component_samples: [aliquot1.sample, aliquot2.sample])
      aliquot1.sample.reload
      aliquot2.sample.reload
    end

    it_behaves_like 'a sequencing procedure'
  end

  context 'when multiple compound samples already exists with the source_aliquot samples' do
    let(:compound_sample1) { create(:sample, name: 'compound_sample_1') }
    let(:compound_sample2) { create(:sample, name: 'compound_sample_2') }

    before do
      compound_sample1.update(component_samples: [aliquot1.sample, aliquot2.sample])
      compound_sample2.update(component_samples: [aliquot1.sample, aliquot2.sample])
      aliquot1.sample.reload
      aliquot2.sample.reload
    end

    it_behaves_like 'a sequencing procedure'
  end
end
