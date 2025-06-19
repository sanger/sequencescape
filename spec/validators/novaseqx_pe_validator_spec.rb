# frozen_string_literal: true

require 'rails_helper'

describe NovaseqxPeValidator do
  describe '#validate' do
    context 'with batch_size_for_flowcell_type validations' do
      let(:record) { create(:batch, request_count: 2) }

      it 'returns true if no requests are selected' do
        record.requests = []
        expect(described_class.new.validate(record)).to be true
      end

      it 'returns true if there are no flowcell_types' do
        record.requests.each { |request| request.request_metadata.requested_flowcell_type = nil }
        expect(described_class.new.validate(record)).to be true
      end

      it 'returns false if there are multiple flowcell_types' do
        record.requests.each { |request| request.request_metadata.requested_flowcell_type = '1.5B' }
        record.requests.first.request_metadata.requested_flowcell_type = '10B'

        expect(described_class.new.validate(record)).to be false
      end

      context 'with flowcells_match_batch_size validations' do
        [
          { flowcell_type: '1.5B', request_count: 2, result: nil },
          { flowcell_type: '1.5B', request_count: 8, result: false },
          { flowcell_type: '10B', request_count: 8, result: nil },
          { flowcell_type: '10B', request_count: 2, result: false },
          { flowcell_type: '10B', request_count: 8, result: nil },
          { flowcell_type: '10B', request_count: 2, result: false }
        ].each do |batch_data|
          it "returns #{batch_data[:result].nil? ? 'nil' : batch_data[:result]} if the flowcell_type is
              #{batch_data[:flowcell_type]} and the request count is #{batch_data[:request_count]}" do
            record = create(:batch, request_count: batch_data[:request_count])
            record.requests.each do |request|
              request.request_metadata.requested_flowcell_type = batch_data[:flowcell_type]
            end
            expect(described_class.new.validate(record)).to be batch_data[:result]
          end
        end

        # We want to check we don't flag anything here as its handled by batch creation validator
        it 'returns nil if the flowcell_type is not 1.5B, 10B, or 25B' do
          record.requests.each { |request| request.request_metadata.requested_flowcell_type = 'Not a flowcell type' }
          expect(described_class.new.validate(record)).to be_nil
        end
      end
    end
  end
end
