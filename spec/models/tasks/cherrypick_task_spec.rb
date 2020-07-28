require 'rails_helper'

RSpec.configure do |c|
  c.include LabWhereClientHelper
end

RSpec.describe CherrypickTask, type: :model do
  let!(:plate) { create :plate_with_untagged_wells, sample_count: 4 }
  let(:control_plate) { create :control_plate, sample_count: 2 }
  let(:requests) { plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w) }.flatten }
  let(:template) { create(:plate_template, size: 6) }
  let(:robot) { double('robot', max_beds: 2) }
  let(:purpose) { create :purpose }
  let(:batch) { double('batch', id: 1235, requests: requests) }
  let(:submission) { create :submission }
  let(:request_type) { create :request_type }

  def pick_without_request_id(plates)
    plates.map { |plate| plate.map { |_id, barcode, pos| [barcode, pos] } }
  end

  def requests_for_plate(plate)
    plate.wells.in_column_major_order.map { |w| create(:cherrypick_request, asset: w) }.flatten
  end

  describe '#pick_new_plate' do
    context 'with control plate' do
      before do
        requests.first.update(submission: submission, request_type: request_type)
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        let(:destinations) do
          [[
            [control_plate.human_barcode, 'B1'],
            [plate.human_barcode, 'A1'],
            [plate.human_barcode, 'B1'],
            [plate.human_barcode, 'C1'],
            [plate.human_barcode, 'D1'],
            [control_plate.human_barcode, 'A1']
          ]]
        end

        it 'generates one plate' do
          pick = described_class.new.pick_new_plate(requests, template, robot, purpose, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with templates' do
        let(:destinations) do
          [
            [
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [plate.human_barcode, 'C1'],
              [control_plate.human_barcode, 'A1'],
              ['---', '']
            ],
            [
              [control_plate.human_barcode, 'A1'],
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'D1'],
              ['Empty', ''],
              ['Empty', ''],
              ['---', '']
            ]
          ]
        end

        before do
          template.wells.create!
          template.wells.first.update(map_id: 6)
        end

        it 'places controls in a different position' do
          pick = described_class.new.pick_new_plate(requests, template, robot, purpose, control_plate)
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
        requests.first.update(submission: submission, request_type: request_type)
        allow(requests.first).to receive(:batch).and_return(batch)
      end

      context 'when controls and wells fit in one plate' do
        let!(:plate) { create :plate_with_untagged_wells, sample_count: 2 }
        let(:destinations) do
          [[
            [control_plate.human_barcode, 'B1'],
            [plate.human_barcode, 'A1'],
            [plate.human_barcode, 'B1'],
            [control_plate.human_barcode, 'A1'],
            ['Empty', ''],
            ['---', '']
          ]]
        end

        it 'generates one plate' do
          pick = described_class.new.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end

      context 'when control positions clashes with partial' do
        let!(:plate) { create :plate_with_untagged_wells, sample_count: 4 }
        let(:destinations) do
          [
            [
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'A1'],
              [plate.human_barcode, 'B1'],
              [plate.human_barcode, 'C1'],
              [control_plate.human_barcode, 'A1'],
              ['---', '']
            ],
            [
              [control_plate.human_barcode, 'A1'],
              [control_plate.human_barcode, 'B1'],
              [plate.human_barcode, 'D1'],
              ['Empty', ''],
              ['Empty', ''],
              ['Empty', '']
            ]
          ]
        end

        it 'places controls in a different position' do
          pick = described_class.new.pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate)
          expect(pick_without_request_id(pick[0])).to eq(destinations)
        end
      end
    end
  end

  describe '#control_positions' do
    it 'calculates the positions for the control wells' do
      # Test batch id 0, plate 0 to 4, 5 free wells, 2 control wells
      expect(described_class.new.control_positions(0, 0, 5, 2)).to eq([0, 1])
      expect(described_class.new.control_positions(0, 1, 5, 2)).to eq([1, 2])
      expect(described_class.new.control_positions(0, 2, 5, 2)).to eq([2, 3])
      expect(described_class.new.control_positions(0, 3, 5, 2)).to eq([3, 4])
      expect(described_class.new.control_positions(0, 4, 5, 2)).to eq([4, 0])
    end

    it 'can allocate all controls in all wells' do
      # Test batch id 0, plate 0, 2 free wells, 2 control wells
      expect(described_class.new.control_positions(0, 0, 2, 2)).to eq([0, 1])
    end

    it 'fails when you try to put more controls than free wells' do
      # Test batch id 0, plate 0, 2 free wells, 3 control wells, so they dont fit
      expect do
        described_class.new.control_positions(0, 0, 2, 3)
      end.to raise_error(ZeroDivisionError)
    end

    it 'does not clash with consecutive batches (1)' do
      # Test batch id 12345, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345, 0, 100, 3)).to eq([45, 24, 1])
      expect(described_class.new.control_positions(12345, 1, 100, 3)).to eq([46, 25, 2])
      expect(described_class.new.control_positions(12345, 2, 100, 3)).to eq([47, 26, 3])
    end

    it 'does not clash with consecutive batches (2)' do
      # Test batch id 12346, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345 + 1, 0, 100, 3)).to eq([46, 24, 1])
      expect(described_class.new.control_positions(12345 + 1, 1, 100, 3)).to eq([47, 25, 2])
      expect(described_class.new.control_positions(12345 + 1, 2, 100, 3)).to eq([48, 26, 3])
    end

    it 'does not clash with consecutive batches (3)' do
      # Test batch id 12445, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345 + 100, 0, 100, 3)).to eq([45, 25, 1])
      expect(described_class.new.control_positions(12345 + 100, 1, 100, 3)).to eq([46, 26, 2])
      expect(described_class.new.control_positions(12345 + 100, 2, 100, 3)).to eq([47, 27, 3])
    end

    it 'does not clash with consecutive batches (4)' do
      # Test batch id 12545, plate 0 to 2, 100 free wells, 3 control wells
      expect(described_class.new.control_positions(12345 + 200, 0, 100, 3)).to eq([45, 26, 1])
      expect(described_class.new.control_positions(12345 + 200, 1, 100, 3)).to eq([46, 27, 2])
      expect(described_class.new.control_positions(12345 + 200, 2, 100, 3)).to eq([47, 28, 3])
    end

    it 'also works with big batch id and small wells' do
      # Test batch id 12545, plate 0 to 4, 3 free wells, 1 control wells
      expect(described_class.new.control_positions(12345, 0, 3, 1)).to eq([0])
      expect(described_class.new.control_positions(12345, 1, 3, 1)).to eq([1])
      expect(described_class.new.control_positions(12345, 2, 3, 1)).to eq([2])
      expect(described_class.new.control_positions(12345, 3, 3, 1)).to eq([0])
      expect(described_class.new.control_positions(12345, 4, 3, 1)).to eq([1])
    end

    it 'does not place controls in the first three columns for a 96-well destination plate' do
      expect(described_class.new.control_positions(12345, 0, 96, 3)).to eq([57, 53, 26])
      expect(described_class.new.control_positions(12345, 1, 96, 3)).to eq([58, 54, 27])
      expect(described_class.new.control_positions(12345, 2, 96, 3)).to eq([59, 55, 28])
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
