require 'rails_helper'

RSpec.describe Asset, type: :model do
  context 'An asset' do
    context 'with a barcode' do
      setup do
        @asset = create :asset
        @result_hash = @asset.barcode_and_created_at_hash
      end
      it 'return a hash with the barcode and created_at time' do
        assert @result_hash.present?
        assert @result_hash.is_a?(Hash)
        assert @result_hash[:barcode].is_a?(String)
        assert @result_hash[:created_at].is_a?(ActiveSupport::TimeWithZone)
      end
    end

    context 'without a barcode' do
      setup do
        @asset = create :asset, barcode: nil
        @result_hash = @asset.barcode_and_created_at_hash
      end
      it 'return an empty hash' do
        assert @result_hash.blank?
      end
    end

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
end
