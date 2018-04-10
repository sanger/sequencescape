require 'rails_helper'

RSpec.describe Asset, type: :model do
  context 'An asset' do
    context '#scanned_in_date' do
      setup do
        @scanned_in_asset = create :asset
        @unscanned_in_asset = create :asset
        @scanned_in_event = create :event, content: Time.zone.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful_type: 'Asset', eventful_id: @scanned_in_asset.id
      end
      it 'return a date if it has been scanned in' do
        assert_equal Time.zone.today.to_s, @scanned_in_asset.scanned_in_date
      end

      it "return nothing if it hasn't been scanned in" do
        assert @unscanned_in_asset.scanned_in_date.blank?
      end
    end
  end

  context '#assign_relationships' do
    context 'with the correct arguments' do
      setup do
        @asset = create :asset
        @parent_asset_1 = create :asset
        @parent_asset_2 = create :asset
        @parents = [@parent_asset_1, @parent_asset_2]
        @child_asset = create :asset

        @asset.assign_relationships(@parents, @child_asset)
      end

      it 'add 2 parents to the asset' do
        assert_equal 2, @asset.reload.parents.size
      end

      it 'add 1 child to the asset' do
        assert_equal 1, @asset.reload.children.size
      end

      it 'set the correct child' do
        assert_equal @child_asset, @asset.reload.children.first
      end

      it 'set the correct parents' do
        assert_equal @parents, @asset.reload.parents
      end
    end

    context 'with the wrong arguments' do
      setup do
        @asset = create :asset
        @parent_asset_1 = create :asset
        @parent_asset_2 = create :asset
        @asset.parents = [@parent_asset_1, @parent_asset_2]
        @parents = [@parent_asset_1, @parent_asset_2]
        @asset.reload
        @child_asset = create :asset

        @asset.assign_relationships(@asset.parents, @child_asset)
      end

      it 'add 2 parents to the asset' do
        assert_equal 2, @asset.reload.parents.size
      end

      it 'add 1 child to the asset' do
        assert_equal 1, @asset.reload.children.size
      end

      it 'set the correct child' do
        assert_equal @child_asset, @asset.reload.children.first
      end

      it 'set the correct parents' do
        assert_equal @parents, @asset.reload.parents
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
          #     plate_fluidigm_1.fluidigm_barcode,
          plate_ean13_2.machine_barcode,
          #    plate_fluidigm_2.fluidigm_barcode
        ]
        expected_result = [
          plate_ean13_1,
          #   plate_fluidigm_1,
          plate_ean13_2,
          #  plate_fluidigm_2
        ]
        expect(Asset.with_barcode(bcs)).to match_array(expected_result)
      end

      it 'finds plates when sent a mixture of valid and invalid barcodes' do
        bcs = [
          plate_ean13_1.machine_barcode,
          'RUBBISH123',
          # plate_fluidigm_1.fluidigm_barcode,
          plate_ean13_2.machine_barcode,
          '1234567890123',
          # plate_fluidigm_2.fluidigm_barcode
        ]
        expected_result = [
          plate_ean13_1,
          # plate_fluidigm_1,
          plate_ean13_2,
          # plate_fluidigm_2
        ]
        expect(Asset.with_barcode(bcs)).to match_array(expected_result)
      end
    end
  end
end
