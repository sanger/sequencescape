# frozen_string_literal: true

require 'rails_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

RSpec.describe CherrypickTask do
  let!(:plate) { create(:plate_with_untagged_wells, sample_count: 4) }
  let(:control_plate) { create(:control_plate, sample_count: 2) }
  let(:requests) do
    plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w, submission: submission) }
  end
  let(:template) { create(:plate_template, size: 6) }
  let(:robot) { instance_double('Robot', max_beds: 2) } # rubocop:todo RSpec/VerifiedDoubleReference
  let(:purpose) { create(:purpose) }
  let(:batch) { instance_double('Batch', id: 1235, requests: requests) } # rubocop:todo RSpec/VerifiedDoubleReference
  let(:submission) { create(:submission) }
  let(:wells_to_leave_free) { Rails.application.config.plate_default_control_wells_to_leave_free }

  def pick_without_request_id(plates)
    plates.map { |plate| plate.map { |_id, barcode, pos| [barcode, pos] } }
  end

  def requests_for_plate(plate)
    plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w) }.flatten
  end

  describe '#pick_new_plate' do
    context 'with control plate' do
      before { allow(requests.first).to receive(:batch).and_return(batch) }

      context 'when controls and wells fit in one plate' do
        before do
          locator = instance_double(CherrypickTask::ControlLocator, control_positions: [2, 5])
          allow(CherrypickTask::ControlLocator).to receive(:new).with(
            batch_id: 1235,
            total_wells: 6,
            num_control_wells: 2,
            wells_to_leave_free: wells_to_leave_free,
            control_source_plate: control_plate,
            template: template
          ).and_return(locator)
          allow(locator).to receive(:handle_incompatible_plates)
        end

        let(:instance) { described_class.new }
        let(:destinations) do
          [
            [
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [control_plate.human_barcode, 'A1'],
              [plate.human_barcode, 'C1'],
              [plate.human_barcode, 'D1'],
              [control_plate.human_barcode, 'B1']
            ]
          ]
        end

        it 'generates one plate' do
          pick = instance.pick_new_plate(requests, template, robot, purpose, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with templates' do
        let(:instance) { described_class.new }
        let(:wells) { build_stubbed_list(:well, 1, map_id: 6) }
        let(:template) { build_stubbed(:plate_template, size: 6, wells: wells) }
        let(:destinations) do
          [
            [
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [control_plate.human_barcode, 'A1'],
              [plate.human_barcode, 'C1'],
              [control_plate.human_barcode, 'B1'], # This control well has moved forward
              ['---', '']
            ],
            [
              [control_plate.human_barcode, 'A1'],
              [plate.human_barcode, 'D1'],
              [control_plate.human_barcode, 'B1'],
              ['Empty', ''],
              ['Empty', ''],
              ['---', '']
            ]
          ]
        end

        before do
          locator = instance_double(CherrypickTask::ControlLocator)
          allow(locator).to receive(:control_positions).and_return([2, 5], [0, 2])
          allow(CherrypickTask::ControlLocator).to receive(:new).and_return(locator)
          allow(locator).to receive(:handle_incompatible_plates)
        end

        it 'places controls in a different position' do
          pick = instance.pick_new_plate(requests, template, robot, purpose, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end
    end
  end

  describe '#pick_onto_partial_plate' do
    let!(:partial_plate) { create(:plate, size: 6) }

    before do
      partial_plate.wells.create!
      partial_plate.wells.first.update(map_id: 6)
    end

    context 'with controls' do
      before do
        requests.first.update(submission:)
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        before do
          locator = instance_double(CherrypickTask::ControlLocator, control_positions: [2, 3])
          allow(CherrypickTask::ControlLocator).to receive(:new).and_return(locator)
          allow(locator).to receive(:handle_incompatible_plates)
        end

        let(:instance) { described_class.new }
        let!(:plate) { create(:plate_with_untagged_wells, sample_count: 2) }
        let(:destinations) do
          [
            [
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [control_plate.human_barcode, 'A1'],
              [control_plate.human_barcode, 'B1'],
              ['Empty', ''],
              ['---', '']
            ]
          ]
        end

        it 'generates one plate' do
          pick = instance.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with partial' do
        before do
          locator = instance_double(CherrypickTask::ControlLocator)
          allow(locator).to receive(:control_positions).and_return([2, 4], [0, 2])
          allow(CherrypickTask::ControlLocator).to receive(:new).and_return(locator)
          allow(locator).to receive(:handle_incompatible_plates)
        end

        let(:instance) { described_class.new }
        let!(:plate) { create(:plate_with_untagged_wells, sample_count: 4) }
        let(:destinations) do
          [
            [
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [control_plate.human_barcode, 'A1'],
              [plate.human_barcode, 'C1'],
              [control_plate.human_barcode, 'B1'],
              ['---', '']
            ],
            [
              [control_plate.human_barcode, 'A1'],
              [plate.human_barcode, 'D1'],
              [control_plate.human_barcode, 'B1'],
              ['Empty', ''],
              ['Empty', ''],
              ['Empty', '']
            ]
          ]
        end

        it 'places controls in a different position' do
          pick = instance.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end
    end
  end

  describe '#build_plate_wells_from_requests' do
    let!(:plate1) { create(:plate_with_untagged_wells, sample_count: 4, name: 'plate1') }
    let!(:plate2) { create(:plate_with_untagged_wells, sample_count: 4, name: 'plate2') }
    let!(:plate3) { create(:plate_with_untagged_wells, sample_count: 4, name: 'plate3') }
    let(:plates) { [plate1, plate2, plate3] }
    let(:requests1) { requests_for_plate(plate1) }
    let(:requests2) { requests_for_plate(plate2) }
    let(:requests3) { requests_for_plate(plate3) }
    let(:requests) { requests1 + requests2 + requests3 }

    let(:location1) { 'Shelf 2' } # Expected order: 2nd
    let(:parentage1) { 'Sanger / Ogilvie / AA316' }

    let(:location2) { 'Shelf 2' } # Expected order: 3rd
    let(:parentage2) { 'Sanger / Ogilvie / AA317' }

    let(:location3) { 'Shelf 1' } # Expected order: 1st
    let(:parentage3) { 'Sanger / Ogilvie / AA316' }

    context 'with locations set' do
      # with locations set we expect requests to be ordered primarily by location parentage
      let(:expected_output) do
        output = []
        requests3.each do |request| # rubocop:disable Style/MapIntoArray
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests1.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests2.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            { lw_barcode: plate1.human_barcode, lw_locn_name: location1, lw_locn_parentage: parentage1 },
            { lw_barcode: plate2.human_barcode, lw_locn_name: location2, lw_locn_parentage: parentage2 },
            { lw_barcode: plate3.human_barcode, lw_locn_name: location3, lw_locn_parentage: parentage3 }
          ]
        )
      end

      it 'sorts by location' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end

    context 'with no locations set' do
      # with no locations, they should just be in plate creation order
      let(:expected_output) do
        output = []
        requests1.each do |request| # rubocop:disable Style/MapIntoArray
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests2.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests3.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            { lw_barcode: plate1.human_barcode, lw_locn_name: '', lw_locn_parentage: '' },
            { lw_barcode: plate2.human_barcode, lw_locn_name: '', lw_locn_parentage: '' },
            { lw_barcode: plate3.human_barcode, lw_locn_name: '', lw_locn_parentage: '' }
          ]
        )
      end

      it 'sorts by location' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end

    context 'with a mix of locations and no locations' do
      # with a mixture we expect plates with no locations to be sorted first then those with locations
      let(:expected_output) do
        output = []

        # no location, should be first
        requests1.each do |request| # rubocop:disable Style/MapIntoArray
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests3.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests2.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            { lw_barcode: plate1.human_barcode, lw_locn_name: '', lw_locn_parentage: '' },
            { lw_barcode: plate2.human_barcode, lw_locn_name: location2, lw_locn_parentage: parentage2 },
            { lw_barcode: plate3.human_barcode, lw_locn_name: location3, lw_locn_parentage: parentage3 }
          ]
        )
      end

      it 'sorts by location' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end

    context 'with multiple plates with same location' do
      # when multiple plates have the same location (e.g. a box) we expect order to be by plate creation
      let(:expected_output) do
        output = []
        requests1.each do |request| # rubocop:disable Style/MapIntoArray
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests2.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        requests3.each do |request|
          output << [request.id, request.asset.plate.human_barcode, request.asset.map_description]
        end
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            { lw_barcode: plate1.human_barcode, lw_locn_name: location1, lw_locn_parentage: parentage1 },
            { lw_barcode: plate2.human_barcode, lw_locn_name: location1, lw_locn_parentage: parentage1 },
            { lw_barcode: plate3.human_barcode, lw_locn_name: location1, lw_locn_parentage: parentage1 }
          ]
        )
      end

      it 'sorts by plate id' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end

    context 'with 1 plate' do
      # redefine requests so we can jumble them up in a different order
      let(:request1) { create(:cherrypick_request, asset: plate1.wells[2]) } # C1
      let(:request2) { create(:cherrypick_request, asset: plate1.wells[0]) } # A1
      let(:request3) { create(:cherrypick_request, asset: plate1.wells[3]) } # D1
      let(:request4) { create(:cherrypick_request, asset: plate1.wells[1]) } # B1
      let!(:requests) { [request1, request2, request3, request4] }

      let(:expected_output) do
        output = []
        output << [request2.id, request2.asset.plate.human_barcode, request2.asset.map_description]
        output << [request4.id, request4.asset.plate.human_barcode, request4.asset.map_description]
        output << [request1.id, request1.asset.plate.human_barcode, request1.asset.map_description]
        output << [request3.id, request3.asset.plate.human_barcode, request3.asset.map_description]
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [{ lw_barcode: plate1.human_barcode, lw_locn_name: '', lw_locn_parentage: '' }]
        )
      end

      it 'sorts by map description' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end
  end
end
