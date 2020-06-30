# frozen_string_literal: true

require 'rails_helper'
require 'broadcast_event/lab_event'

RSpec.describe Robot::Verification::SourceDestControlBeds do
  subject(:verifier) { described_class.new }

  describe '#pick_number_to_expected_layout' do # expected_layout(batch, destination_plate_barcode)
    let(:source_plate_1) { create :plate, well_count: 2 }
    let(:source_plate_3) { create :plate, well_count: 2 }
    let(:destination_plate) { create :plate, well_count: 9 }
    let(:pipeline) { create :cherrypick_pipeline }
    let(:max_beds) { 17 }

    let(:transfers) do
      # We generate the plates before the transfer map, as otherwise
      # our random re-ordering of them is pointless!
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
        create :cherrypick_request,
               asset: source,
               target_asset: target,
               request_type: pipeline.request_types.first,
               state: 'passed'
      end
    end

    let(:batch) { create :batch, requests: requests, pipeline: pipeline }
    let(:user) { create :user }
    let(:robot) { create :hamilton, barcode: '444' }

    context 'without control plates' do
      let(:source_plate_2) { create :plate, well_count: 2 }
      let(:expected_layout) do
        [
          { destination_plate.machine_barcode => 1 }, # Destinations
          {
            source_plate_3.machine_barcode => 1,
            source_plate_2.machine_barcode => 2,
            source_plate_1.machine_barcode => 3
          }, # Sources
          {} # Controls
        ]
      end

      let(:params) do
        {
          bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824' },
          plate_barcodes: {
            source_plate_3.machine_barcode => source_plate_3.machine_barcode,
            source_plate_2.machine_barcode => source_plate_2.machine_barcode,
            source_plate_1.machine_barcode => source_plate_1.machine_barcode
          },
          plate_types: {
            source_plate_3.machine_barcode => 'ABgene_0765',
            source_plate_2.machine_barcode => 'ABgene_0765',
            source_plate_1.machine_barcode => 'ABgene_0765',
            destination_plate.machine_barcode => 'ABgene_0800'
          },
          destination_bed_barcodes: { '1' => '580000026663' },
          destination_plate_barcodes: { destination_plate.machine_barcode => destination_plate.machine_barcode },
          commit: 'Verify',
          barcodes: {
            destination_plate_barcode: destination_plate.machine_barcode
          },
          batch_id: batch.id,
          robot_id: robot.id,
          user_id: user.id,
          pick_number: 1
        }
      end

      it 'generates a layout' do
        expect(verifier.pick_number_to_expected_layout(batch, destination_plate.human_barcode, max_beds)[1]).to eq(expected_layout)
      end

      it 'is is a valid submission' do
        expect(verifier.valid_submission?(params)).to eq true
      end
    end

    context 'with control plates' do
      let(:source_plate_2) do
        create :control_plate, well_count: 2
      end
      let(:expected_layout) do
        [
          { destination_plate.machine_barcode => 1 }, # Destinations
          {
            source_plate_3.machine_barcode => 1,
            source_plate_1.machine_barcode => 2
          }, # Sources
          {
            source_plate_2.machine_barcode => 1
          } # Controls
        ]
      end

      let(:params) do
        {
          bed_barcodes: { '1' => '580000001806', '2' => '580000002810' },
          plate_barcodes: {
            source_plate_3.machine_barcode => source_plate_3.machine_barcode,
            source_plate_1.machine_barcode => source_plate_1.machine_barcode
          },
          plate_types: {
            source_plate_3.machine_barcode => 'ABgene_0765',
            source_plate_2.machine_barcode => 'ABgene_0765',
            source_plate_1.machine_barcode => 'ABgene_0765',
            destination_plate.machine_barcode => 'ABgene_0800'
          },
          control_bed_barcodes: { '1' => '580000025659' },
          control_plate_barcodes: { source_plate_2.machine_barcode => source_plate_2.machine_barcode },
          destination_bed_barcodes: { '1' => '580000026663' },
          destination_plate_barcodes: { destination_plate.machine_barcode => destination_plate.machine_barcode },
          commit: 'Verify',
          barcodes: {
            destination_plate_barcode: destination_plate.machine_barcode
          },
          batch_id: batch.id,
          robot_id: robot.id,
          user_id: user.id,
          pick_number: 1
        }
      end

      it 'generates a layout' do
        expect(verifier.pick_number_to_expected_layout(batch, destination_plate.human_barcode, max_beds)[1]).to eq(expected_layout)
      end

      it 'is is a valid submission' do
        expect(verifier.valid_submission?(params)).to eq true
      end
    end
  end
end
