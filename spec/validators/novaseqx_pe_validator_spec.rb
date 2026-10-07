# frozen_string_literal: true

require 'rails_helper'

describe NovaseqxPeValidator do
  describe '#validate' do
    context 'with batch_size_for_flowcell_type validations' do
      let(:record) { create(:batch, request_count: 2) }

      it 'adds no errors if no requests are selected' do
        record.requests = []
        described_class.new.validate(record)
        expect(record.errors).to be_empty
      end

      it 'adds no errors if there are no flowcell_types' do
        record.requests.each do |request|
          request.request_metadata.requested_flowcell_type = nil
        end
        described_class.new.validate(record)
        expect(record.errors).to be_empty
      end

      # Mixed flowcell types are reported by BatchCreationValidator,
      # so nothing is flagged here
      context 'when there are multiple flowcell_types' do
        before do
          record.requests.each do |request|
            request.request_metadata.requested_flowcell_type = '1.5B'
          end
          record.requests.first.request_metadata.requested_flowcell_type = '10B'
        end

        it 'adds no errors' do
          described_class.new.validate(record)
          expect(record.errors).to be_empty
        end
      end

      context 'with flowcells_match_batch_size validations' do
        [
          { flowcell_type: '1.5B', batch_size: 2, request_count: 2 },
          { flowcell_type: '1.5B', batch_size: 2, request_count: 8 },
          { flowcell_type: '5B', batch_size: 8, request_count: 8 },
          { flowcell_type: '5B', batch_size: 8, request_count: 2 },
          { flowcell_type: '10B', batch_size: 8, request_count: 8 },
          { flowcell_type: '10B', batch_size: 8, request_count: 2 },
          { flowcell_type: '25B', batch_size: 8, request_count: 8 },
          { flowcell_type: '25B', batch_size: 8, request_count: 2 }
        ].each do |batch_data|
          context "when the flowcell_type is #{batch_data[:flowcell_type]} " \
                  "and the request count is #{batch_data[:request_count]}" do
            let(:record) do
              create(:batch, request_count: batch_data[:request_count])
            end
            let(:error) do
              format('You must select exactly %<batch_size>d requests ' \
                     'for %<flowcell_type>s flowcells', batch_data)
            end

            before do
              record.requests.map(&:request_metadata).each do |metadata|
                metadata.requested_flowcell_type = batch_data[:flowcell_type]
              end
              described_class.new.validate(record)
            end

            if batch_data[:request_count] == batch_data[:batch_size]
              it 'adds no errors' do
                expect(record.errors).to be_empty
              end
            else
              it 'adds a batch size error' do
                expect(record.errors[:base]).to contain_exactly(error)
              end
            end
          end
        end

        # Unknown flowcell types are ignored here; rejected at submission.
        context 'when the flowcell_type has no batch size rule' do
          # 3 is not a valid batch size for any flowcell type,
          # so no errors means the check was skipped.
          let(:record) { create(:batch, request_count: 3) }

          before do
            record.requests.each do |request|
              request.request_metadata.requested_flowcell_type = 'Unknown'
            end
          end

          it 'skips the batch size check' do
            described_class.new.validate(record)
            expect(record.errors).to be_empty
          end
        end
      end
    end
  end
end
