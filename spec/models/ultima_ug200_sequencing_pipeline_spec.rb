# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UltimaUG200SequencingPipeline do
  let(:pipeline) do
    described_class.new(
      workflow: Workflow.new,
      request_types: [create(:ultima_ug200_sequencing)]
    )
  end

  describe '#ot_recipe_consistent_for_batch?' do
    it 'returns true when all requests have the same ot_recipe' do
      batch = pipeline.batches.build
      r1 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      r2 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      batch.requests << [r1, r2]

      expect(pipeline.ot_recipe_consistent_for_batch?(batch)).to be true
    end

    it 'returns false when requests have different ot_recipes' do
      batch = pipeline.batches.build
      req1 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      req2 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { ot_recipe: 'Flex' })
      batch.requests << [req1, req2]

      expect(pipeline.ot_recipe_consistent_for_batch?(batch)).to be false
    end

    it 'returns false when some requests are missing ot_recipe' do
      batch = pipeline.batches.build
      r1 = create(:sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      r2 = create(:sequencing_request, request_metadata_attributes: {}) # no ot_recipe
      batch.requests << [r1, r2]

      expect(pipeline.ot_recipe_consistent_for_batch?(batch)).to be false
    end
  end

  describe '#wafer_size_consistent_for_batch?' do
    it 'returns true when all requests have the same wafer_size' do
      batch = pipeline.batches.build
      r1 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { wafer_size: '10TB' })
      r2 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { wafer_size: '10TB' })
      batch.requests << [r1, r2]

      expect(pipeline.wafer_size_consistent_for_batch?(batch)).to be true
    end

    it 'returns false when requests have different wafer_sizes' do
      batch = pipeline.batches.build
      req1 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { wafer_size: '5TB' })
      req2 = create(:ultima_ug200_sequencing_request, request_metadata_attributes: { wafer_size: '10TB' })
      batch.requests << [req1, req2]

      expect(pipeline.wafer_size_consistent_for_batch?(batch)).to be false
    end

    # NB. Wafer size is a required field, so cannot be missing. Tested in the request spec.
  end

  describe '#post_release_batch' do
    let(:batch) { create(:batch) }

    it 'calls Messenger with UseqWaferIo template and useq_wafer root' do
      allow(Messenger).to receive(:create!)
      pipeline.post_release_batch(batch, create(:user))

      expect(Messenger).to have_received(:create!).with(
        hash_including(target: batch, template: 'UseqWaferIo', root: 'useq_wafer')
      )
    end
  end
end
