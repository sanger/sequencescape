# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robot::PickData do
  subject(:pick_data) { described_class.new(batch, destination_plate.machine_barcode) }

  around do |example|
    travel_to(time) do
      example.run
    end
  end

  describe '#picking_data' do
    let(:time) { Time.zone.local(2010, 7, 12, 10, 25, 0) }
    let(:source_plate_1) { create :plate, well_count: 2 }
    let(:source_plate_3) { create :plate, well_count: 2 }
    let(:destination_plate) { create :plate, well_count: 9 }
    let(:pipeline) { create :cherrypick_pipeline }

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
        create :cherrypick_request,
               asset: source,
               target_asset: target,
               request_type: pipeline.request_types.first,
               state: 'passed'
      end
    end

    let(:user) { create :user }

    let(:batch) { create :batch, requests: requests, pipeline: pipeline, user: user }

    context 'without control plates' do
      let(:source_plate_2) { create :plate, well_count: 2 }
      let(:expected_picking_data) do
        {
          'destination' => {
            destination_plate.machine_barcode => {
              'mapping' => [
                { 'buffer_volume' => 0.0, 'dst_well' => 'A1', 'src_well' => [source_plate_3.machine_barcode, 'A1'], 'volume' => nil },
                { 'buffer_volume' => 0.0, 'dst_well' => 'F1', 'src_well' => [source_plate_2.machine_barcode, 'B1'], 'volume' => nil },
                { 'buffer_volume' => 0.0, 'dst_well' => 'D1', 'src_well' => [source_plate_1.machine_barcode, 'B1'], 'volume' => nil },
                { 'buffer_volume' => 0.0, 'dst_well' => 'B1', 'src_well' => [source_plate_2.machine_barcode, 'A1'], 'volume' => nil },
                { 'buffer_volume' => 0.0, 'dst_well' => 'C1', 'src_well' => [source_plate_3.machine_barcode, 'B1'], 'volume' => nil },
                { 'buffer_volume' => 0.0, 'dst_well' => 'A2', 'src_well' => [source_plate_1.machine_barcode, 'A1'], 'volume' => nil }
              ],
              'name' => 'ABgene 0800',
              'plate_size' => 96,
              'control' => false
            }
          },
          'source' => {
            source_plate_1.machine_barcode => {
              'control' => false,
              'name' => 'ABgene 0800',
              'plate_size' => 96
            },
            source_plate_2.machine_barcode => {
              'control' => false,
              'name' => 'ABgene 0800',
              'plate_size' => 96
            },
            source_plate_3.machine_barcode => {
              'control' => false,
              'name' => 'ABgene 0800',
              'plate_size' => 96
            }
          },
          'time' => time,
          'user' => user.login
        }
      end

      it 'generates a layout' do
        expect(pick_data.picking_data).to eq(expected_picking_data)
      end
    end
  end
end
