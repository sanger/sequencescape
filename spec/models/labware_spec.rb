# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

RSpec.describe Labware, type: :model do
  describe '#assign_relationships' do
    context 'with the correct arguments' do
      let(:labware) { create(:labware) }
      let(:parent_labware_1) { create(:labware) }
      let(:parent_labware_2) { create(:labware) }
      let(:parents) { [parent_labware_1, parent_labware_2] }
      let(:child_labware) { create(:labware) }

      before { labware.assign_relationships(parents, child_labware) }

      it 'adds 2 parents to the labware' do
        expect(labware.reload.parents.size).to eq(2)
      end

      it 'adds 1 child to the labware' do
        expect(labware.reload.children.size).to eq(1)
      end

      it 'sets the correct child' do
        expect(child_labware).to eq(labware.reload.children.first)
      end

      it 'sets the correct parents' do
        expect(parents).to eq(labware.reload.parents)
      end
    end

    context 'with the wrong arguments' do
      let(:labware) { create(:labware) }
      let(:parent_labware_1) { create(:labware) }
      let(:parent_labware_2) { create(:labware) }
      let(:parents) { [parent_labware_1, parent_labware_2] }
      let(:child_labware) { create(:labware) }

      before do
        labware.parents = [parent_labware_1, parent_labware_2]
        labware.reload
        labware.assign_relationships(labware.parents, child_labware)
      end

      it 'adds 2 parents to the labware' do
        expect(labware.reload.parents.size).to eq(2)
      end

      it 'adds 1 child to the labware' do
        expect(labware.reload.children.size).to eq(1)
      end

      it 'sets the correct child' do
        expect(child_labware).to eq(labware.reload.children.first)
      end

      it 'sets the correct parents' do
        expect(parents).to eq(labware.reload.parents)
      end
    end
  end

  describe 'spiked_in_buffer' do
    let(:labware) { create(:labware) }
    let(:parent_labware) { create(:labware) }
    let(:spiked_buffer_parent) { create :spiked_buffer, :tube_barcode }
    let(:spiked_buffer_child) { create :spiked_buffer, :tube_barcode }

    before { labware.parents << parent_labware }

    context 'when there is a direct parent SpikedBuffer tube and an indirect ancestor' do
      before do
        # Create the SpikedBuffer child before the parent
        # Tests obscure (but existing) case in historical data
        spiked_buffer_child
        spiked_buffer_parent
        spiked_buffer_child.parents << spiked_buffer_parent

        # Add the SpikedBuffer as a direct parent of this labware
        labware.parents << spiked_buffer_child
      end

      it 'returns the SpikedBuffer linked directly to this labware' do
        # Check the child was created before the parent
        expect(spiked_buffer_child.id).to be < spiked_buffer_parent.id

        # Order of creation should be ignored in this case, because there is a direct SpikedBuffer parent
        expect(labware.spiked_in_buffer).to eq(spiked_buffer_child)
      end
    end

    context 'when there are no direct parent SpikedBuffer tubes, and multiple indirect ancestors' do
      before do
        # Create the SpikedBuffer child after the parent (normal expected scenario)
        spiked_buffer_parent
        spiked_buffer_child
        spiked_buffer_child.parents << spiked_buffer_parent

        # Add the SpikedBuffer as a parent of the labware one level up
        parent_labware.parents << spiked_buffer_child
      end

      it 'returns the most recently created SpikedBuffer' do
        # Check the child was created after the parent
        expect(spiked_buffer_child.id).to be > spiked_buffer_parent.id

        # The child SpikedBuffer was created most recently, so it will choose that.
        # As a proxy for the most direct ancestor, assuming parents get created before children.
        expect(labware.spiked_in_buffer).to eq(spiked_buffer_child)
      end
    end

    context 'when there is no SpikedBuffer ancestor at all' do
      it 'returns nil' do
        expect(labware.spiked_in_buffer).to be_nil
      end
    end
  end

  context 'when checking scopes' do
    describe '#with_barcode' do
      let!(:ean13_plates_list) { create_list(:plate_with_tagged_wells, 2) }
      let!(:fluidigm_plates_list) { create_list(:plate_with_fluidigm_barcode, 2) }

      let(:plate_ean13_1) { ean13_plates_list[0] }
      let(:plate_ean13_2) { ean13_plates_list[1] }

      let(:plate_fluidigm_1) { fluidigm_plates_list[0] }
      let(:plate_fluidigm_2) { fluidigm_plates_list[1] }

      it 'correctly finds a single ean13 barcode' do
        expect(described_class.with_barcode(plate_ean13_1.machine_barcode)).to match_array([plate_ean13_1])
      end

      it 'does not find anything when sent a non-valid ean13 barcode' do
        expect(described_class.with_barcode('1234567890123')).to match_array([])
      end

      it 'correctly finds a plate with a single fluidigm barcode' do
        expect(described_class.with_barcode(plate_fluidigm_1.fluidigm_barcode)).to match_array([plate_fluidigm_1])
      end

      it 'does not find anything when sent any other string' do
        expect(described_class.with_barcode('INVALID123ABC')).to match_array([])
      end

      context 'with valid barcodes' do
        let(:searched_barcodes) do
          [
            plate_ean13_1.machine_barcode,
            plate_fluidigm_1.fluidigm_barcode,
            plate_ean13_2.machine_barcode,
            plate_fluidigm_2.fluidigm_barcode
          ]
        end
        let(:expected_result) { [plate_ean13_1, plate_fluidigm_1, plate_ean13_2, plate_fluidigm_2] }

        it 'finds plates' do
          expect(described_class.with_barcode(searched_barcodes)).to match_array(expected_result)
        end
      end

      context 'with valid and invalid barcodes' do
        let(:searched_barcodes) do
          [
            plate_ean13_1.machine_barcode,
            'RUBBISH123',
            plate_fluidigm_1.fluidigm_barcode,
            plate_ean13_2.machine_barcode,
            '1234567890123',
            plate_fluidigm_2.fluidigm_barcode
          ]
        end
        let(:expected_result) { [plate_ean13_1, plate_fluidigm_1, plate_ean13_2, plate_fluidigm_2] }

        it 'finds plates' do
          expect(described_class.with_barcode(searched_barcodes)).to match_array(expected_result)
        end
      end
    end
  end

  context 'when retrieving labwhere locations' do
    describe '#labwhere_location' do
      subject { plate.labwhere_location }

      let(:plate) { create :plate, barcode: 1 }
      let(:parentage) { 'Sanger / Ogilvie / AA316' }
      let(:location) { 'Shelf 1' }

      before do
        stub_lwclient_labware_find_by_bc(
          lw_barcode: plate.human_barcode,
          lw_locn_name: location,
          lw_locn_parentage: parentage
        )
        stub_lwclient_labware_find_by_bc(
          lw_barcode: plate.machine_barcode,
          lw_locn_name: location,
          lw_locn_parentage: parentage
        )
      end

      it { is_expected.to eq "#{parentage} - #{location}" }
    end

    describe '#labwhere_locations' do
      subject { described_class.labwhere_locations(barcodes) }

      let(:plate_1) { create :plate, barcode: 1 }
      let(:plate_2) { create :plate, barcode: 2 }
      let(:barcodes) { [plate_1.human_barcode, plate_2.human_barcode] }
      let(:parentage_1) { 'Sanger / Ogilvie / AA316' }
      let(:parentage_2) { 'Sanger / Ogilvie / AA317' }
      let(:location_1) { 'Shelf 1' }
      let(:location_2) { 'Shelf 2' }
      let(:expected) do
        {
          plate_1.human_barcode => "#{parentage_1} - #{location_1}",
          plate_2.human_barcode => "#{parentage_2} - #{location_2}"
        }
      end

      before do
        stub_lwclient_labware_bulk_find_by_bc(
          [
            { lw_barcode: plate_1.human_barcode, lw_locn_name: location_1, lw_locn_parentage: parentage_1 },
            { lw_barcode: plate_2.human_barcode, lw_locn_name: location_2, lw_locn_parentage: parentage_2 }
          ]
        )
      end

      it { is_expected.to eq expected }
    end
  end

  describe 'labwhere_location' do
    it 'returns not found when a LabWhereClient error is raised' do
      allow(LabWhereClient::Labware).to receive(:find_by_barcode).and_raise(
        StandardError,
        'Timed out reading data from server'
      )

      plate = create(:plate, barcode: 1)
      expect(plate.storage_location).to eq('Not found - There is a problem with Labwhere')
    end
  end
end
