# frozen_string_literal: true

require 'rails_helper'

describe PoolingSourcePlatePurpose do
  describe '#_pool_wells' do
    subject(:pooled_wells) { pooling_source_plate_purpose.send(:_pool_wells, Well.where(id: well.id)) }

    let(:pooling_source_plate_purpose) { described_class.new }
    let(:well) { create(:well) }
    let(:submission) { create(:submission) }

    %w[pending started].each do |state|
      context "when a source multiplexing request is #{state}" do
        before { create(:multiplex_request, asset: well, submission: submission, state: state) }

        it 'uses the multiplexing request submission as the pool' do
          expect(pooled_wells.map(&:pool_id)).to eq([submission.id])
        end
      end
    end

    context 'when the source multiplexing request has passed' do
      before { create(:multiplex_request, asset: well, submission: submission, state: 'passed') }

      it 'uses transfer pooling instead' do
        expect(pooled_wells.map(&:pool_id)).to eq([nil])
      end
    end
  end
end
