# frozen_string_literal: true
require 'rails_helper'

describe UltimaUG200Validator do
  describe '#validate' do
    subject(:validator) { described_class.new }

    let(:pipeline) { UltimaUG200SequencingPipeline.new }
    let(:batch) { create(:batch, pipeline:) }
    let(:requests) { [request1, request2] }
    let(:request1_metadata) { { ot_recipe: 'Free', wafer_size: '10TB' } }
    let(:request2_metadata) { { ot_recipe: 'Free', wafer_size: '10TB' } }
    let(:request1) { create(:ultima_sequencing_request, request_metadata_attributes: request1_metadata) }
    let(:request2) { create(:ultima_sequencing_request, request_metadata_attributes: request2_metadata) }

    before do
      batch.requests << requests
    end

    context 'when batch contains two requests with the same OT Recipe' do
      it 'is valid' do
        validator.validate(batch)
        expect(batch.errors[:base]).to be_empty
      end
    end

    context 'when batch contains two requests with different ot_recipe' do
      let(:request2_metadata) { { ot_recipe: 'Flex', wafer_size: '10TB' } }

      it 'is invalid due to ot_recipe mismatch' do
        validator.validate(batch)
        expect(batch.errors[:base]).to include(described_class::OT_RECIPE_CONSISTENT_MSG)
      end
    end

    context 'when batch contains two requests with the same Wafer Size' do
      it 'is valid' do
        validator.validate(batch)
        expect(batch.errors[:base]).not_to include(described_class::WAFER_SIZE_CONSISTENT_MSG)
      end
    end

    context 'when batch contains two requests with different wafer_size' do
      let(:request1_metadata) { { ot_recipe: 'Free', wafer_size: '5TB' } }

      it 'is invalid due to wafer_size mismatch' do
        validator.validate(batch)
        expect(batch.errors[:base]).to include(described_class::WAFER_SIZE_CONSISTENT_MSG)
      end
    end

    context 'when batch contains a single request' do
      let(:requests) { [request1] }

      it 'is invalid' do
        validator.validate(batch)
        expect(batch.errors[:base]).to include(described_class::TWO_REQUESTS_MSG)
      end
    end
  end
end
