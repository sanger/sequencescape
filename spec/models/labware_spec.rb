# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labware, type: :model do
  describe '#assign_relationships' do
    context 'with the correct arguments' do
      let(:labware) { create(:labware) }
      let(:parent_labware_1) { create(:labware) }
      let(:parent_labware_2) { create(:labware) }
      let(:parents) { [parent_labware_1, parent_labware_2] }
      let(:child_labware) { create(:labware) }

      before do
        labware.assign_relationships(parents, child_labware)
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
        let(:expected_result) do
          [
            plate_ean13_1,
            plate_fluidigm_1,
            plate_ean13_2,
            plate_fluidigm_2
          ]
        end

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
        let(:expected_result) do
          [
            plate_ean13_1,
            plate_fluidigm_1,
            plate_ean13_2,
            plate_fluidigm_2
          ]
        end

        it 'finds plates' do
          expect(described_class.with_barcode(searched_barcodes)).to match_array(expected_result)
        end
      end
    end
  end
end
