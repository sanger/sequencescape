# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UltimaSequencingPipeline, type: :model do
  let(:pipeline) do
    described_class.new(
      workflow: Workflow.new,
      request_types: [create(:ultima_sequencing)]
    )
  end

  describe '#ot_recipe_consistent_for_batch?' do
    it 'returns true when all requests have the same ot_recipe' do
      batch = pipeline.batches.build
      r1 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      r2 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      batch.requests << [r1, r2]

      expect(pipeline.ot_recipe_consistent_for_batch?(batch)).to be true
    end

    it 'returns false when requests have different ot_recipes' do
      batch = pipeline.batches.build
      req1 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      req2 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Flex' })
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

    it 'returns true when no requests have ot_recipe' do
      batch = pipeline.batches.build
      r1 = create(:sequencing_request, request_metadata_attributes: {})
      r2 = create(:sequencing_request, request_metadata_attributes: {})
      batch.requests << [r1, r2]

      expect(pipeline.ot_recipe_consistent_for_batch?(batch)).to be true
    end
  end
end
