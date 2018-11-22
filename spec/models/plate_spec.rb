# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe Plate do
  context 'barcodes' do
    # Maintaining existing barcode behaviour
    context 'sanger barcodes' do
      let(:prefix) { 'DN' }
      let(:barcode_prefix) { create :barcode_prefix, prefix: prefix }
      let(:plate) { create :plate, prefix: prefix, barcode: '12345' }

      describe '#human_barcode' do
        subject { plate.human_barcode }
        it { is_expected.to eq 'DN12345U' }
      end

      describe '#human_barcode' do
        subject { plate.human_barcode }
        it { is_expected.to eq 'DN12345U' }
      end

      describe '#ean13_barcode' do
        subject { plate.ean13_barcode }
        it { is_expected.to eq '1220012345855' }
      end
    end
  end
  # Pools are horrendously complicated

  describe '#pools' do
    include_context 'a limber target plate with submissions'

    subject { target_plate.pools }

    context 'before passing' do
      let(:expected_pools_hash) do
        {
          target_submission.uuid => {
            wells: %w[A1 B1 C1],
            insert_size: { from: 1, to: 20 },
            library_type: { name: 'Standard' },
            request_type: library_request_type.key, pcr_cycles: nil,
            pool_complete: false,
            for_multiplexing: false
          }
        }
      end

      it { is_expected.to eq expected_pools_hash }
    end

    context 'after passing' do
      before do
        WorkCompletion.create!(
          user: create(:user),
          target: target_plate,
          submissions: [target_submission]
        )
      end

      context 'with downstream requests' do
        let(:expected_pools_hash) do
          {
            target_submission.uuid => {
              wells: %w[A1 B1 C1],
              request_type: multiplex_request_type.key,
              pool_complete: false,
              for_multiplexing: true
            }
          }
        end

        it { is_expected.to eq expected_pools_hash }
      end

      describe 'input_plate#pools' do
        subject { input_plate.pools }
        let(:expected_pools_hash) do
          {
            target_submission.uuid => {
              wells: %w[A1 B1 C1],
              insert_size: { from: 1, to: 20 },
              library_type: { name: 'Standard' },
              request_type: library_request_type.key, pcr_cycles: nil,
              pool_complete: true,
              for_multiplexing: false
            },
            decoy_submission.uuid => {
              wells: %w[A1 B1 C1],
              insert_size: { from: 1, to: 20 },
              library_type: { name: 'Standard' },
              request_type: library_request_type.key, pcr_cycles: nil,
              pool_complete: false,
              for_multiplexing: false
            }
          }
        end

        it { is_expected.to eq expected_pools_hash }
      end

      context 'without downstream requests' do
        let(:submission_request_types) { [library_request_type] }
        let(:expected_pools_hash) { {} }

        it { is_expected.to eq expected_pools_hash }
      end
    end
  end
end
