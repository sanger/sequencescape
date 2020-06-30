# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robot::PickData do
  subject(:pick_data) { described_class.new(batch, destination_plate.machine_barcode) }

  around do |example|
    travel_to(time) do
      example.run
    end
  end

  describe '#picking_data_hash' do
    subject(:pick_data) { described_class.new(batch, destination_plate.machine_barcode, max_beds: 2) }

    let(:time) { Time.zone.local(2010, 7, 12, 10, 25, 0) }
    let(:source_plate_1) { create :plate, well_count: 2 }
    let(:source_plate_3) { create :plate, well_count: 2 }
    let(:destination_plate) { create :plate, well_count: 9 }
    let(:pipeline) { create :cherrypick_pipeline }

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

    let(:user) { create :user }

    let(:batch) { create :batch, requests: requests, pipeline: pipeline, user: user }

    context 'without control plates' do
      let(:source_plate_2) { create :plate, well_count: 2 }
      let(:expected_picking_data_hash) do
        {
          1 => {
            'destination' => {
              destination_plate.machine_barcode => {
                'name' => 'ABgene 0800',
                'plate_size' => 96,
                'control' => false,
                'mapping' => [
                  { 'src_well' => [source_plate_3.machine_barcode, 'A1'], 'dst_well' => 'A1', 'volume' => nil, 'buffer_volume' => 0.0 },
                  { 'src_well' => [source_plate_2.machine_barcode, 'B1'], 'dst_well' => 'F1', 'volume' => nil, 'buffer_volume' => 0.0 },
                  { 'src_well' => [source_plate_2.machine_barcode, 'A1'], 'dst_well' => 'B1', 'volume' => nil, 'buffer_volume' => 0.0 },
                  { 'src_well' => [source_plate_3.machine_barcode, 'B1'], 'dst_well' => 'C1', 'volume' => nil, 'buffer_volume' => 0.0 }
                ]
              }
            },
            'source' => {
              source_plate_3.machine_barcode => {
                'name' => 'ABgene 0800',
                'plate_size' => 96,
                'control' => false
              },
              source_plate_2.machine_barcode => {
                'name' => 'ABgene 0800',
                'plate_size' => 96,
                'control' => false
              }
            },
            'time' => time,
            'user' => user.login
          },
          2 => {
            'destination' => {
              destination_plate.machine_barcode => {
                'name' => 'ABgene 0800',
                'plate_size' => 96,
                'control' => false,
                'mapping' => [
                  { 'src_well' => [source_plate_1.machine_barcode, 'B1'], 'dst_well' => 'D1', 'volume' => nil, 'buffer_volume' => 0.0 },
                  { 'src_well' => [source_plate_1.machine_barcode, 'A1'], 'dst_well' => 'A2', 'volume' => nil, 'buffer_volume' => 0.0 }
                ]
              }
            },
            'source' => {
              source_plate_1.machine_barcode => {
                'name' => 'ABgene 0800',
                'plate_size' => 96,
                'control' => false
              }
            },
            'time' => time,
            'user' => user.login
          }
        }
      end

      it 'generates a layout' do
        actual = pick_data.picking_data_hash
        # puts "actual"
        # pp actual
        # puts "expected"
        # pp expected_picking_data_hash
        expect(actual).to eq(expected_picking_data_hash)
      end
    end
  end
end
