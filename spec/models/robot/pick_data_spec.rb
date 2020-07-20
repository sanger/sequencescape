# frozen_string_literal: true

require 'rails_helper'
require './spec/models/robot/pick_hash_tester_helper'

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
      picks.keys.reduce({}) do |memo, dest_location|
        dest_well = destination_plate.wells.located_at(dest_location).first
        src_well = picks[dest_location][0].wells.located_at(picks[dest_location][1]).first
        memo[src_well] = dest_well
        memo
      end
      # {
      #   source_plate_3.wells[0] => destination_wells[0],
      #   source_plate_2.wells[1] => destination_wells[5],
      #   source_plate_1.wells[1] => destination_wells[3],
      #   source_plate_2.wells[0] => destination_wells[1],
      #   source_plate_3.wells[1] => destination_wells[2],
      #   source_plate_1.wells[0] => destination_wells[8]
      # }
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

    shared_examples_for 'a picking process' do
      

      #context 'without control plates' do
      
      # let(:expected_picking_data_hash) do
      #   expected_pick.keys.reduce do |memo, pick_number|
      #     memo[pick_number] = picks_from_wells(expected_pick[pick_number])
      #   {
      #     1 => {
      #       'destination' => {
      #         destination_plate.machine_barcode => {
      #           'name' => 'ABgene 0800',
      #           'plate_size' => 96,
      #           'control' => false,
      #           'mapping' => [
      #             { 'src_well' => [source_plate_3.machine_barcode, 'A1'], 'dst_well' => 'A1', 'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_2.machine_barcode, 'A1'], 'dst_well' => 'B1', 'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_3.machine_barcode, 'B1'], 'dst_well' => 'C1', 'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_2.machine_barcode, 'B1'], 'dst_well' => 'F1', 'volume' => nil, 'buffer_volume' => 0.0 }
      #           ]
      #         }
      #       },
      #       'source' => {
      #         source_plate_3.machine_barcode => {
      #           'name' => 'ABgene 0800',
      #           'plate_size' => 96,
      #           'control' => false
      #         },
      #         source_plate_2.machine_barcode => {
      #           'name' => 'ABgene 0800',
      #           'plate_size' => 96,
      #           'control' => false
      #         }
      #       },
      #       'time' => time,
      #       'user' => user.login
      #     },
      #     2 => {
      #       'destination' => {
      #         destination_plate.machine_barcode => {
      #           'name' => 'ABgene 0800',
      #           'plate_size' => 96,
      #           'control' => false,
      #           'mapping' => [
      #             { 'src_well' => [source_plate_1.machine_barcode, 'B1'], 'dst_well' => 'D1', 'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_1.machine_barcode, 'A1'], 'dst_well' => 'A2', 'volume' => nil, 'buffer_volume' => 0.0 }
      #           ]
      #         }
      #       },
      #       'source' => {
      #         source_plate_1.machine_barcode => {
      #           'name' => 'ABgene 0800',
      #           'plate_size' => 96,
      #           'control' => false
      #         }
      #       },
      #       'time' => time,
      #       'user' => user.login
      #     }
      #   }
      # end

      it 'generates a layout' do
        helper = PickHashTesterHelper.new(destination_plate, picks, time, user)
        obtained = pick_data.picking_data_hash
  
        expect(expected_pick.keys).to eq(obtained.keys)
        expected_pick.keys.each do |pick_number|
          expectation = helper.pickings_for(expected_pick[pick_number])
          expect(obtained[pick_number]).to eq(expectation)
        end
  
        #actual = pick_data.picking_data_hash
        # puts "actual"
        # pp actual
        # puts "expected"
        # pp expected_picking_data_hash
        #expect(actual).to eq(expected_picking_data_hash)
      end
    end

    context 'when request have been created out of order' do
      let(:source_plate_2) { create :plate, well_count: 2 }
      let(:picks) {
        {
          'A1' => [source_plate_3, 'A1'],
          'F1' => [source_plate_2, 'B1'],
          'D1' => [source_plate_1, 'B1'],
          'B1' => [source_plate_2, 'A1'],
          'C1' => [source_plate_3, 'B1'],
          'A2' => [source_plate_1, 'A1']
        }
      }
      let(:expected_pick) {
        {
          1 => ['A1', 'B1', 'C1', 'F1'],
          2 => ['D1', 'A2']
        }
      }
      it_behaves_like 'a picking process'
    end

  end
end
