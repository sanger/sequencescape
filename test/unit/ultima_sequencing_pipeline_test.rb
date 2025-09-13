# frozen_string_literal: true

require 'test_helper'

class UltimaSequencingPipelineTest < ActiveSupport::TestCase
  setup do
    @pipeline =
      UltimaSequencingPipeline.new(
        workflow: Workflow.new,
        request_types: [create(:sequencing_request_type)]
      )
  end

  context '#ot_recipe_consistent_for_batch?' do
    should 'return true when batch is empty' do
      batch = @pipeline.batches.build
      assert @pipeline.ot_recipe_consistent_for_batch?(batch)
    end

    should 'return true when all requests have the same ot_recipe' do
      batch = @pipeline.batches.build
      r1 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      r2 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      batch.requests << [r1, r2]

      assert @pipeline.ot_recipe_consistent_for_batch?(batch)
    end

    should 'return false when requests have different ot_recipes' do
      batch = @pipeline.batches.build
      req1 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      req2 = create(:ultima_sequencing_request, request_metadata_attributes: { ot_recipe: 'Flex' })

      batch.requests << [req1, req2]

      assert_not @pipeline.ot_recipe_consistent_for_batch?(batch)
    end

    should 'return false when some requests are missing ot_recipe' do
      batch = @pipeline.batches.build
      r1 = create(:sequencing_request, request_metadata_attributes: { ot_recipe: 'Free' })
      r2 = create(:sequencing_request, request_metadata_attributes: {}) # no ot_recipe
      batch.requests << [r1, r2]

      assert_not @pipeline.ot_recipe_consistent_for_batch?(batch)
    end
  end
end
