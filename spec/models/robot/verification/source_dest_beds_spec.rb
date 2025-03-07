# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robot::Verification::SourceDestBeds, :robot_verification do
  subject(:verifier) { described_class.new }

  # We test pick_number_to_expected_layout and pick_numbers with shared contexts
  # as it is important that they both show the same behaviour.
  # @note pick_numbers collects the behaviour that was originally in batches/_assets
  #       and extracts it into a method to allow testing and optimization. The original
  #       implementation was as simple as pick_number_to_expected_layout(...).keys
  context 'with a pick' do
    shared_examples 'it generates layout information' do
      describe '#pick_number_to_expected_layout' do
        it 'generates a layout' do
          expect(verifier.pick_number_to_expected_layout(batch, destination_plate.human_barcode, max_beds)).to eq(
            expected_layout
          )
        end
      end

      describe '#pick_numbers' do
        it 'generates a list' do
          expect(verifier.pick_numbers(batch, destination_plate.human_barcode, max_beds)).to eq(expected_layout.keys)
        end
      end

      describe '#all_picks' do
        it 'generates a list of all picks' do
          expect(verifier.all_picks(batch, max_beds)).to eq(all_picks)
        end
      end
    end

    let(:source_plate_1) { create(:plate, well_count: 2) }
    let(:source_plate_3) { create(:plate, well_count: 2) }
    let(:destination_plate) { create(:plate, well_count: 9) }
    let(:pipeline) { create(:cherrypick_pipeline) }
    let(:max_beds) { 17 }

    let(:transfers) do
      # We generate the plates before the transfer map, as otherwise
      # or random re-ordering of them is pointless!
      source_plate_1
      source_plate_2
      source_plate_3
      destination_wells = destination_plate.wells.in_column_major_order

      # These are specified in an odd order to ensure we are sorting by
      # destination well, not request id, or other side effects of creation order
      {
        source_plate_3.wells[0] => destination_wells[0],
        source_plate_2.wells[1] => destination_wells[5],
        source_plate_1.wells[1] => destination_wells[3],
        source_plate_2.wells[0] => destination_wells[1],
        source_plate_3.wells[1] => destination_wells[2],
        source_plate_1.wells[0] => destination_wells[8]
      }
    end

    let(:requests) do
      transfers.map do |source, target|
        create(
          :cherrypick_request,
          asset: source,
          target_asset: target,
          request_type: pipeline.request_types.first,
          state: 'passed'
        )
      end
    end

    let(:batch) { create(:batch, requests:, pipeline:) }

    context 'without control plates' do
      let(:source_plate_2) { create(:plate, well_count: 2) }
      let(:expected_layout) do
        {
          1 => [
            { destination_plate.machine_barcode => 1 }, # Destinations
            {
              source_plate_3.machine_barcode => 1,
              source_plate_2.machine_barcode => 3,
              source_plate_1.machine_barcode => 2
            }
          ]
        }
      end

      let(:all_picks) { { destination_plate.machine_barcode => expected_layout } }

      it_behaves_like 'it generates layout information'
    end

    context 'with control plates' do
      let(:source_plate_2) { create(:control_plate, well_count: 2) }
      let(:expected_layout) do
        {
          1 => [
            { destination_plate.machine_barcode => 1 }, # Destinations
            {
              source_plate_3.machine_barcode => 1,
              source_plate_2.machine_barcode => 3,
              source_plate_1.machine_barcode => 2
            }
          ]
        }
      end

      let(:all_picks) { { destination_plate.machine_barcode => expected_layout } }

      it_behaves_like 'it generates layout information'
    end
  end

  # Pulled from original tests. While I like the testing via the data object, these are now private methods
  # so probably shouldn't be tested.
  describe '#barcode_to_plate_index' do
    let(:barcodes) { { '1111' => 'aaa', '5555' => 'tttt', '4444' => 'bbbb', '7777' => 'zzzz' } }
    let(:plate_index_lookup) { verifier.send(:barcode_to_plate_index, barcodes) }

    it 'remaps barcode ids to start at 1' do
      barcodes.each do |key, _value|
        assert plate_index_lookup[key].is_a?(Integer)
        expect(plate_index_lookup[key]).to be_between(1, barcodes.length)
      end
    end

    it 'does not add extra plates' do
      expect(barcodes.length).to eq(plate_index_lookup.length)
    end
  end

  describe '#source_barcode_to_plate_index' do
    let(:plate) { create(:plate_with_fluidigm_barcode) }
    let(:barcodes) do
      {
        plate.machine_barcode => {
          'mapping' => [
            { 'src_well' => %w[88888 A11], 'dst_well' => 'S011', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[66666 H7], 'dst_well' => 'S093', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[99999 C7], 'dst_well' => 'S031', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[88888 A1], 'dst_well' => 'S001', 'volume' => 13, 'buffer_volume' => 0.0 }
          ]
        }
      }
    end
    let(:source_index) { verifier.send(:source_barcode_to_plate_index, barcodes) }
    let(:expected_order) { { '88888' => 1, '99999' => 2, '66666' => 3 } }

    it 'remap barcodes to start at 1' do
      expected_order.each do |source_barcode, _index|
        assert source_index[source_barcode].is_a?(Integer)
        expect(source_index[source_barcode]).to be_positive
      end
    end

    it 'order source plates by destination well barcode to match the way the robot picks' do
      expect(source_index).to eq(expected_order)
    end
  end

  describe '#sort_mapping_by_destination_well' do
    let(:plate) { create(:plate_with_fluidigm_barcode) }
    let(:mapping) do
      [
        { 'src_well' => %w[88888 A11], 'dst_well' => 'S011', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' => %w[66666 H7], 'dst_well' => 'S093', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' => %w[99999 C7], 'dst_well' => 'S031', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' => %w[88888 A1], 'dst_well' => 'S001', 'volume' => 13, 'buffer_volume' => 0.0 }
      ]
    end
    let(:expected_order) do
      [
        { 'src_well' => %w[88888 A1], 'dst_well' => 'S001', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' => %w[88888 A11], 'dst_well' => 'S011', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' => %w[99999 C7], 'dst_well' => 'S031', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' => %w[66666 H7], 'dst_well' => 'S093', 'volume' => 13, 'buffer_volume' => 0.0 }
      ]
    end

    it 'sort mapping by the destination well barcode' do
      expect(verifier.send(:sort_mapping_by_destination_well, plate.machine_barcode, mapping)).to eq expected_order
    end
  end
end
