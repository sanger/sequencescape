require "test_helper"

class LotTest < ActiveSupport::TestCase
  context "A Lot" do


    should_validate_presence_of :lot_number

    should_have_many :qcables
    should_belong_to :user
    should_belong_to :lot_type
    should_validate_presence_of :user
    should_validate_presence_of :received_at
    should_belong_to :template

    context "when validating" do
      setup do
        Factory :lot
      end

      should_validate_uniqueness_of :lot_number
    end


    context "#lot" do
      setup do
        PlateBarcode.stubs(:create).returns(OpenStruct.new(:barcode => (Factory.next :barcode)))
        @lot = Factory :lot
        @mock_asset = Asset.new
        @mock_asset.stubs(:save!).returns(true)
        @mock_purpose = mock('Purpose')

        @mock_purpose.stubs('create!').returns(@mock_asset)
        @lot.stubs(:target_purpose).returns(@mock_purpose)
        @user = Factory :user
      end

      should "validate the template type" do
        @lot.template = Factory :tag_layout_template, :name => 'lot_test'
        assert !@lot.valid?, 'Lot should be invalid'
      end

      teardown do
        @lot.lot_type.delete
        @lot.delete
      end
    end

  end

end
