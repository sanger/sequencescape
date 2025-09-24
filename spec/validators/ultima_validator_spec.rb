# frozen_string_literal: true
require 'rails_helper'

describe UltimaValidator do
  describe '#validate' do
    subject(:validator) { described_class.new }

    context 'when batch contains two requests with the same OT Recipe' do
      et(:pipeline) { UltimaSequencingPipeline.new }
      let(:batch) { create(:batch, pipeline: pipeline) }
      let(:metadata) { create(:request_metadata, ot_recipe: 'Free') }
      let(:request1) { create(:ultima_sequencing_request, request_metadata: metadata) }
      let(:request2) { create(:ultima_sequencing_request, request_metadata: metadata) }

      before do
        batch.requests << [request1, request2]
      end

      it 'is valid' do
        validator.validate(batch)
        expect(batch.errors[:base]).to be_empty
      end
    end

    context 'when batch contains two requests with different ot_recipe' do
      let(:pipeline) { UltimaSequencingPipeline.new }
      let(:batch) { create(:batch, pipeline: pipeline) }
      let(:metadata1) { create(:request_metadata, ot_recipe: 'Free') }
      let(:metadata2) { create(:request_metadata, ot_recipe: 'Flex') }
      let(:request1) { create(:ultima_sequencing_request, request_metadata: metadata1) }
      let(:request2) { create(:ultima_sequencing_request, request_metadata: metadata2) }

      before do
        batch.requests << [request1, request2]
      end

      it "is invalid due to ot_recipe mismatch" do
        validator.validate(batch)
        expect(batch.errors[:base]).to include(described_class::OT_RECIPE_CONSISTENT_MSG)
      end
    end

    context 'when batch contains a single request' do
      let(:batch) { create(:batch, request_count: 1) }

      it 'is invalid' do
        validator.validate(batch)
        expect(batch.errors[:base]).to include(described_class::TWO_REQUESTS_MSG)
      end
    end

  end
end
