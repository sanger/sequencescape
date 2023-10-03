# frozen_string_literal: true

require 'rails_helper'
require './spec/models/robot/pick_hash_tester_helper'

RSpec.describe Robot::PickData, :robot_verification do
  subject(:pick_data) { described_class.new(batch, max_beds: 2) }

  before { travel_to(time) }



  describe '#picking_data_hash' do
    let(:time) { Time.zone.local(2010, 7, 12, 10, 25, 0) }
    let(:source_plate_1) { create :plate, well_count: 2 }
    let(:source_plate_2) { create :plate, well_count: 2 }
    let(:source_plate_3) { create :plate, well_count: 2 }
    let(:destination_plate) { create :plate, well_count: 9 }
    let(:pipeline) { create :cherrypick_pipeline }

    let(:transfers) do
      # We generate the plates before the transfer map, as otherwise
      # our random re-ordering of them is pointless!
      source_plate_1
      source_plate_2
      source_plate_3

      # These are specified in an odd order to ensure we are sorting by
      # destination well, not request id, or other side effects of creation order
      picks
        .keys
        .each_with_object({}) do |dest_location, memo|
          dest_well = destination_plate.wells.located_at(dest_location).first
          src_well = picks[dest_location][0].wells.located_at(picks[dest_location][1]).first
          memo[src_well] = dest_well
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
      # This is how the output of the process should be displayed:
      #   {
      #     1 => {
      #       'destination' => {
      #         destination_plate.machine_barcode => {
      #           'name' => 'ABgene 0800',
      #           'plate_size' => 96,
      #           'control' => false,
      #           'mapping' => [
      #             { 'src_well' => [source_plate_3.machine_barcode, 'A1'], 'dst_well' => 'A1',
      #               'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_2.machine_barcode, 'A1'], 'dst_well' => 'B1',
      #               'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_3.machine_barcode, 'B1'], 'dst_well' => 'C1',
      #               'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_2.machine_barcode, 'B1'], 'dst_well' => 'F1',
      #               'volume' => nil, 'buffer_volume' => 0.0 }
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
      #             { 'src_well' => [source_plate_1.machine_barcode, 'B1'], 'dst_well' => 'D1',
      #               'volume' => nil, 'buffer_volume' => 0.0 },
      #             { 'src_well' => [source_plate_1.machine_barcode, 'A1'], 'dst_well' => 'A2',
      #               'volume' => nil, 'buffer_volume' => 0.0 }
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
      let(:obtained) { pick_data.picking_data_hash(destination_plate.machine_barcode) }
      let(:helper) { PickHashTesterHelper.new(destination_plate, picks, time, user) }

      it 'generates a layout' do
        expect(expected_pick.keys).to eq(obtained.keys)
        expected_pick.each_key do |pick_number|
          expect(obtained[pick_number]).to eq(helper.pickings_for(expected_pick[pick_number]))
        end
      end
    end

    context 'when request have been created out of order' do
      let(:picks) do
        {
          'A1' => [source_plate_3, 'A1'],
          'F1' => [source_plate_2, 'B1'],
          'D1' => [source_plate_1, 'B1'],
          'B1' => [source_plate_2, 'A1'],
          'C1' => [source_plate_3, 'B1'],
          'A2' => [source_plate_1, 'A1']
        }
      end
      let(:expected_pick) { { 1 => %w[A1 B1 C1 F1], 2 => %w[D1 A2] } }

      it_behaves_like 'a picking process'
    end

    context 'when we have several plates and needs to use several picks' do
      let(:destination_plate) { create :plate, well_count: 10 }
      let(:plates) { create_list :plate, 5, well_count: 2 }
      let(:picks) do
        {
          'A1' => [plates[0], 'A1'],
          'B1' => [plates[0], 'B1'],
          'C1' => [plates[1], 'A1'],
          'D1' => [plates[1], 'B1'],
          'E1' => [plates[2], 'A1'],
          'F1' => [plates[2], 'B1'],
          'G1' => [plates[3], 'A1'],
          'H1' => [plates[3], 'B1'],
          'A2' => [plates[4], 'A1'],
          'B2' => [plates[4], 'B1']
        }
      end
      let(:expected_pick) { { 1 => %w[A1 B1 C1 D1], 2 => %w[E1 F1 G1 H1], 3 => %w[A2 B2] } }

      it_behaves_like 'a picking process'

      context 'when we create the requests in different order' do
        let(:requests) do
          transfers.to_a.reverse.map do |source, target|
            create :cherrypick_request,
                   asset: source,
                   target_asset: target,
                   request_type: pipeline.request_types.first,
                   state: 'passed'
          end
        end

        it_behaves_like 'a picking process'

        context 'when we have a control' do
          let(:control_plate) { create :control_plate, sample_count: 2 }
          let(:expected_pick) { { 1 => %w[A2 B2 A1 B1], 2 => %w[C1 D1 E1 F1], 3 => %w[G1 H1] } }

          before { plates[4] = control_plate }

          it_behaves_like 'a picking process'
        end
      end
    end
  end
end
