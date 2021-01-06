require 'rails_helper'
require 'prime'

RSpec.configure do |c|
  c.include LabWhereClientHelper
end

# Only using this while I refactor
# rubocop:todo RSpec/AnyInstance
RSpec.describe CherrypickTask, type: :model do
  let!(:plate) { create :plate_with_untagged_wells, sample_count: 4 }
  let(:control_plate) { create :control_plate, sample_count: 2 }
  let(:requests) { plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w, submission: submission) } }
  let(:template) { create(:plate_template, size: 6) }
  let(:robot) { double('robot', max_beds: 2) }
  let(:purpose) { create :purpose }
  let(:batch) { double('batch', id: 1235, requests: requests) }
  let(:submission) { create :submission }

  def pick_without_request_id(plates)
    plates.map { |plate| plate.map { |_id, barcode, pos| [barcode, pos] } }
  end

  def requests_for_plate(plate)
    plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w) }.flatten
  end

  describe '#pick_new_plate' do
    context 'with control plate' do
      before do
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        before do
          allow(instance).to receive(:control_positions).and_return([2, 5])
        end

        let(:instance) { described_class.new }
        let(:destinations) do
          [[
            [plate.human_barcode, 'A1'],
            [plate.human_barcode, 'B1'],
            [control_plate.human_barcode, 'A1'],
            [plate.human_barcode, 'C1'],
            [plate.human_barcode, 'D1'],
            [control_plate.human_barcode, 'B1']
          ]]
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
          allow(instance).to receive(:control_positions).and_return([2, 5], [0, 2])
        end

        it 'places controls in a different position' do
          pick = instance.pick_new_plate(requests, template, robot, purpose, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end
    end
  end

  describe '#pick_onto_partial_plate' do
    let!(:partial_plate) { create :plate, size: 6 }

    before do
      partial_plate.wells.create!
      partial_plate.wells.first.update(map_id: 6)
    end

    context 'with controls' do
      before do
        requests.first.update(submission: submission)
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        before do
          allow(instance).to receive(:control_positions).and_return([2, 3])
        end

        let(:instance) { described_class.new }
        let!(:plate) { create :plate_with_untagged_wells, sample_count: 2 }
        let(:destinations) do
          [[
            [plate.human_barcode, 'A1'],
            [plate.human_barcode, 'B1'],
            [control_plate.human_barcode, 'A1'],
            [control_plate.human_barcode, 'B1'],
            ['Empty', ''],
            ['---', '']
          ]]
        end

        it 'generates one plate' do
          pick = instance.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with partial' do
        before do
          allow(instance).to receive(:control_positions).and_return([2, 4], [0, 2])
        end

        let(:instance) { described_class.new }
        let!(:plate) { create :plate_with_untagged_wells, sample_count: 4 }
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

  describe '#control_positions' do
    let(:instance) { described_class.new }

    context 'when all inputs are right' do
      let(:random_list) { [25, 9, 95] }

      before do
        allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:random_elements_from_list).and_return(random_list)
      end

      it 'calculates the positions for the control wells', aggregate_failures: true do
        # Test batch id 0, plate 0 to 4, 5 free wells, 2 control wells
        expect(instance.control_positions(0, 0, 96, 3)).to eq(random_list)
        expect(instance.control_positions(0, 1, 96, 3)).to eq([78, 62, 52])
        expect(instance.control_positions(0, 2, 96, 3)).to eq([35, 19, 9])
      end
    end

    context 'when there are more controls than available positions' do
      it 'raises an error' do
        expect { instance.control_positions(0, 0, 2, 3) }.to raise_error(StandardError)
        expect { instance.control_positions(0, 0, 96, 97) }.to raise_error(StandardError)
        expect { instance.control_positions(0, 0, 96, 8, wells_to_leave_free: 89) }.to raise_error(StandardError)
        expect { instance.control_positions(0, 0, 96, 8, wells_to_leave_free: 88) }.not_to raise_error
      end
    end

    context 'with different arguments' do
      let(:instance) { described_class.new }

      context 'when checking the call for #random_elements_from_list' do
        it 'uses the right arguments' do
          allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:random_elements_from_list).with([0, 1, 2, 3, 4], 3, 0).and_return([0, 1, 2])
          instance.control_positions(0, 0, 5, 3)
          allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:random_elements_from_list).with([2, 3, 4], 3, 0).and_return([0, 1, 2])
          instance.control_positions(0, 0, 5, 3, wells_to_leave_free: 2)
        end

        context 'when num plate exceeds available positions' do
          it 'changes the seed' do
            allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:random_elements_from_list).with([0, 1, 2, 3, 4], 3, 66).and_return([0, 1, 2])
            instance.control_positions(33, 5, 5, 3)
            allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:random_elements_from_list).with([0, 1, 2, 3, 4], 3, 99).and_return([0, 1, 2])
            instance.control_positions(33, 10, 5, 3)
          end
        end
      end

      context 'when checking the call for #control_positions_for_plate' do
        before do
          allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:random_elements_from_list).and_return([1, 4, 3])
          allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:control_positions_for_plate)
        end

        it 'uses the right arguments' do
          allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:control_positions_for_plate).with(0, [1, 4, 3], [0, 1, 2, 3, 4])
          instance.control_positions(0, 0, 5, 3)
          allow_any_instance_of(CherrypickTask::ControlLocator).to receive(:control_positions_for_plate).with(3, [1, 4, 3], [1, 2, 3, 4])
          instance.control_positions(0, 3, 5, 3, wells_to_leave_free: 1)
        end
      end
    end

    it 'fails when you try to put more controls than free wells' do
      # Test batch id 0, plate 0, 2 free wells, 3 control wells, so they dont fit
      expect do
        described_class.new.control_positions(0, 0, 2, 3)
      end.to raise_error(StandardError, 'More controls than free wells')
    end

    it 'gets the same result with same batch and num plate' do
      expect(described_class.new.control_positions(12345, 0, 100, 3)).to(
        eq(described_class.new.control_positions(12345, 0, 100, 3))
      )
    end

    it 'does not get same result with a different plate in same batch' do
      expect(described_class.new.control_positions(12345, 0, 100, 3)).not_to(
        eq(described_class.new.control_positions(12345, 1, 100, 3))
      )
    end

    it 'does not get the same result with a different batch' do
      expect(described_class.new.control_positions(12345, 0, 100, 3)).not_to(
        eq(described_class.new.control_positions(12346, 0, 100, 3))
      )
    end

    context 'when num plate is higher than available positions' do
      it 'does not get same result with a different plate in same batch' do
        expect(described_class.new.control_positions(12345, 0, 100, 3)).not_to(
          eq(described_class.new.control_positions(12345, 100, 100, 3))
        )
      end

      it 'does not get the same result with a different batch' do
        expect(described_class.new.control_positions(12345, 0, 100, 3)).not_to(
          eq(described_class.new.control_positions(12346, 100, 100, 3))
        )
      end
    end

    it 'does not place controls in the first three columns for a 96-well destination plate' do
      # positions 0 - 24
      positions = described_class.new.control_positions(12345, 0, 96, 3, wells_to_leave_free: 24)
      expect(positions).to(be_all { |p| p >= 24 })
    end
  end

  describe '#build_plate_wells_from_requests' do
    let!(:plate_1) { create :plate_with_untagged_wells, sample_count: 4, name: 'plate1' }
    let!(:plate_2) { create :plate_with_untagged_wells, sample_count: 4, name: 'plate2' }
    let!(:plate_3) { create :plate_with_untagged_wells, sample_count: 4, name: 'plate3' }
    let(:plates) { [plate_1, plate_2, plate_3] }
    let(:requests_1) { requests_for_plate(plate_1) }
    let(:requests_2) { requests_for_plate(plate_2) }
    let(:requests_3) { requests_for_plate(plate_3) }
    let(:requests) { requests_1 + requests_2 + requests_3 }

    let(:location_1) { 'Shelf 2' } # Expected order: 2nd
    let(:parentage_1) { 'Sanger / Ogilvie / AA316' }

    let(:location_2) { 'Shelf 2' } # Expected order: 3rd
    let(:parentage_2) { 'Sanger / Ogilvie / AA317' }

    let(:location_3) { 'Shelf 1' } # Expected order: 1st
    let(:parentage_3) { 'Sanger / Ogilvie / AA316' }

    context 'with locations set' do
      # with locations set we expect requests to be ordered primarily by location parentage
      let(:expected_output) do
        output = []
        requests_3.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_1.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_2.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            {
              lw_barcode: plate_1.human_barcode,
              lw_locn_name: location_1,
              lw_locn_parentage: parentage_1
            },
            {
              lw_barcode: plate_2.human_barcode,
              lw_locn_name: location_2,
              lw_locn_parentage: parentage_2
            },
            {
              lw_barcode: plate_3.human_barcode,
              lw_locn_name: location_3,
              lw_locn_parentage: parentage_3
            }
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
        requests_1.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_2.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_3.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            {
              lw_barcode: plate_1.human_barcode,
              lw_locn_name: '',
              lw_locn_parentage: ''
            },
            {
              lw_barcode: plate_2.human_barcode,
              lw_locn_name: '',
              lw_locn_parentage: ''
            },
            {
              lw_barcode: plate_3.human_barcode,
              lw_locn_name: '',
              lw_locn_parentage: ''
            }
          ]
        )
      end

      it 'sorts by location' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end

    context 'with a mix of locations and no locations' do
      # with a mixture we expect plates woth no locations to be sorted first then those with locations
      let(:expected_output) do
        output = []
        requests_1.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] } # no location, should be first
        requests_3.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_2.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            {
              lw_barcode: plate_1.human_barcode,
              lw_locn_name: '',
              lw_locn_parentage: ''
            },
            {
              lw_barcode: plate_2.human_barcode,
              lw_locn_name: location_2,
              lw_locn_parentage: parentage_2
            },
            {
              lw_barcode: plate_3.human_barcode,
              lw_locn_name: location_3,
              lw_locn_parentage: parentage_3
            }
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
        requests_1.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_2.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        requests_3.each { |request| output << [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            {
              lw_barcode: plate_1.human_barcode,
              lw_locn_name: location_1,
              lw_locn_parentage: parentage_1
            },
            {
              lw_barcode: plate_2.human_barcode,
              lw_locn_name: location_1,
              lw_locn_parentage: parentage_1
            },
            {
              lw_barcode: plate_3.human_barcode,
              lw_locn_name: location_1,
              lw_locn_parentage: parentage_1
            }
          ]
        )
      end

      it 'sorts by plate id' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end

    context 'with 1 plate' do
      # redefine requests so we can jumble them up in a different order
      let(:request_1) { create(:cherrypick_request, asset: plate_1.wells[2]) } # C1
      let(:request_2) { create(:cherrypick_request, asset: plate_1.wells[0]) } # A1
      let(:request_3) { create(:cherrypick_request, asset: plate_1.wells[3]) } # D1
      let(:request_4) { create(:cherrypick_request, asset: plate_1.wells[1]) } # B1
      let!(:requests) { [request_1, request_2, request_3, request_4] }

      let(:expected_output) do
        output = []
        output << [request_2.id, request_2.asset.plate.human_barcode, request_2.asset.map_description]
        output << [request_4.id, request_4.asset.plate.human_barcode, request_4.asset.map_description]
        output << [request_1.id, request_1.asset.plate.human_barcode, request_1.asset.map_description]
        output << [request_3.id, request_3.asset.plate.human_barcode, request_3.asset.map_description]
        output
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            {
              lw_barcode: plate_1.human_barcode,
              lw_locn_name: '',
              lw_locn_parentage: ''
            }
          ]
        )
      end

      it 'sorts by map description' do
        expect(described_class.new.build_plate_wells_from_requests(requests)).to eq expected_output
      end
    end
  end
end

# Only using this while I refactor
# rubocop:enable RSpec/AnyInstance
