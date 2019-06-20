require 'rails_helper'

RSpec.describe Asset, type: :model do
  context '#assign_relationships' do
    context 'with the correct arguments' do
      let(:asset) { create(:asset) }
      let(:parent_asset_1) { create(:asset) }
      let(:parent_asset_2) { create(:asset) }
      let(:parents) { [parent_asset_1, parent_asset_2] }
      let(:child_asset) { create(:asset) }

      before do
        asset.assign_relationships(parents, child_asset)
      end

      it 'adds 2 parents to the asset' do
        expect(asset.reload.parents.size).to eq(2)
      end

      it 'adds 1 child to the asset' do
        expect(asset.reload.children.size).to eq(1)
      end

      it 'sets the correct child' do
        expect(child_asset).to eq(asset.reload.children.first)
      end

      it 'sets the correct parents' do
        expect(parents).to eq(asset.reload.parents)
      end
    end

    context 'with the wrong arguments' do
      let(:asset) { create(:asset) }
      let(:parent_asset_1) { create(:asset) }
      let(:parent_asset_2) { create(:asset) }
      let(:parents) { [parent_asset_1, parent_asset_2] }
      let(:child_asset) { create(:asset) }

      before do
        asset.parents = [parent_asset_1, parent_asset_2]
        asset.reload
        asset.assign_relationships(asset.parents, child_asset)
      end

      it 'adds 2 parents to the asset' do
        expect(asset.reload.parents.size).to eq(2)
      end

      it 'adds 1 child to the asset' do
        expect(asset.reload.children.size).to eq(1)
      end

      it 'sets the correct child' do
        expect(child_asset).to eq(asset.reload.children.first)
      end

      it 'sets the correct parents' do
        expect(parents).to eq(asset.reload.parents)
      end
    end
  end

  context 'when checking scopes' do
    context '#with_barcode' do
      let!(:ean13_plates_list) { create_list(:plate_with_tagged_wells, 2) }
      let!(:fluidigm_plates_list) { create_list(:plate_with_fluidigm_barcode, 2) }

      let(:plate_ean13_1) { ean13_plates_list[0] }
      let(:plate_ean13_2) { ean13_plates_list[1] }

      let(:plate_fluidigm_1) { fluidigm_plates_list[0] }
      let(:plate_fluidigm_2) { fluidigm_plates_list[1] }

      it 'correctly finds a single ean13 barcode' do
        expect(Asset.with_barcode(plate_ean13_1.machine_barcode)).to match_array([plate_ean13_1])
      end

      it 'does not find anything when sent a non-valid ean13 barcode' do
        expect(Asset.with_barcode('1234567890123')).to match_array([])
      end

      it 'correctly finds a plate with a single fluidigm barcode' do
        expect(Asset.with_barcode(plate_fluidigm_1.fluidigm_barcode)).to match_array([plate_fluidigm_1])
      end

      it 'does not find anything when sent any other string' do
        expect(Asset.with_barcode('INVALID123ABC')).to match_array([])
      end

      it 'finds plates when sent a mixture of valid barcodes' do
        bcs = [
          plate_ean13_1.machine_barcode,
          plate_fluidigm_1.fluidigm_barcode,
          plate_ean13_2.machine_barcode,
          plate_fluidigm_2.fluidigm_barcode
        ]
        expected_result = [
          plate_ean13_1,
          plate_fluidigm_1,
          plate_ean13_2,
          plate_fluidigm_2
        ]
        expect(Asset.with_barcode(bcs)).to match_array(expected_result)
      end

      it 'finds plates when sent a mixture of valid and invalid barcodes' do
        bcs = [
          plate_ean13_1.machine_barcode,
          'RUBBISH123',
          plate_fluidigm_1.fluidigm_barcode,
          plate_ean13_2.machine_barcode,
          '1234567890123',
          plate_fluidigm_2.fluidigm_barcode
        ]
        expected_result = [
          plate_ean13_1,
          plate_fluidigm_1,
          plate_ean13_2,
          plate_fluidigm_2
        ]
        expect(Asset.with_barcode(bcs)).to match_array(expected_result)
      end
    end
  end

  context 'when checking scopes' do
    describe '#with_barcode' do
      let!(:ean13_plates_list) { create_list(:plate, 2) }
      #    let!(:fluidigm_plates_list) { create_list(:plate_with_fluidigm_barcode, 2) }

      let(:plate_ean13_1) { ean13_plates_list[0] }
      let(:plate_ean13_2) { ean13_plates_list[1] }

      #   let(:plate_fluidigm_1) { fluidigm_plates_list[0] }
      #  let(:plate_fluidigm_2) { fluidigm_plates_list[1] }

      it 'correctly finds a single ean13 barcode' do
        expect(Asset.with_barcode(plate_ean13_1.machine_barcode)).to match_array([plate_ean13_1])
      end

      it 'does not find anything when sent a non-valid ean13 barcode' do
        expect(Asset.with_barcode('1234567890123')).to match_array([])
      end

      it 'correctly finds a plate with a single fluidigm barcode' do
        #    expect(Asset.with_barcode(plate_fluidigm_1.fluidigm_barcode)).to match_array([plate_fluidigm_1])
      end

      it 'does not find anything when sent any other string' do
        expect(Asset.with_barcode('INVALID123ABC')).to match_array([])
      end

      it 'finds plates when sent a mixture of valid barcodes' do
        bcs = [
          plate_ean13_1.machine_barcode,
          plate_ean13_2.machine_barcode
        ]
        expected_result = [
          plate_ean13_1,
          plate_ean13_2
        ]
        expect(Asset.with_barcode(bcs)).to match_array(expected_result)
      end

      it 'finds plates when sent a mixture of valid and invalid barcodes' do
        bcs = [
          plate_ean13_1.machine_barcode,
          'RUBBISH123',
          # plate_fluidigm_1.fluidigm_barcode,
          plate_ean13_2.machine_barcode,
          '1234567890123'
          # plate_fluidigm_2.fluidigm_barcode
        ]
        expected_result = [
          plate_ean13_1,
          # plate_fluidigm_1,
          plate_ean13_2
          # plate_fluidigm_2
        ]
        expect(Asset.with_barcode(bcs)).to match_array(expected_result)
      end
    end
  end
end
