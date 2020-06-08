# frozen_string_literal: true

require 'rails_helper'
require 'broadcast_event/lab_event'

RSpec.describe Hamilton do
  subject(:hamilton) { described_class.new }

  describe '#expected_layout' do # expected_layout(batch, destination_plate_barcode)
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

    let(:batch) { create :batch, requests: requests, pipeline: pipeline }

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

      it 'generates a layout' do
        expect(hamilton.expected_layout(batch, destination_plate.human_barcode)).to eq(expected_layout)
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

      it 'generates a layout' do
        expect(hamilton.expected_layout(batch, destination_plate.human_barcode)).to eq(expected_layout)
      end
    end
  end
end
