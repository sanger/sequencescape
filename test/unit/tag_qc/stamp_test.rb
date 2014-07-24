require "test_helper"

class StampTest < ActiveSupport::TestCase
  context "A Stamp" do

    should_belong_to :user
    should_belong_to :robot
    should_belong_to :lot

    should_have_many :qcables
    should_have_many :stamp_qcables

    should_validate_presence_of :tip_lot
    should_validate_presence_of :user
    should_validate_presence_of :robot
    should_validate_presence_of :lot


    context "#stamp" do
      should 'transition qcables to pending' do
        @qcable = Factory :qcable_with_asset
        # Unfortunately we can't do this, as stamp looks for qcables directly.
        # @qcable.expects(:do_stamp!).returns(true)
        sqc = Stamp::StampQcable.new(:bed=>'1',:order=>1,:qcable=>@qcable)
        @stamp = Factory :stamp, :stamp_qcables => [sqc]
        assert_equal 'pending', @qcable.reload.state
      end

      should 'transfer samples' do
        @qcable = Factory :qcable_with_asset
        # Unfortunately we can't do this, as stamp looks for qcables directly.
        # @qcable.expects(:do_stamp!).returns(true)

        sqc = Stamp::StampQcable.new(:bed=>'1',:order=>1,:qcable=>@qcable)
        @stamp = Factory :stamp, :stamp_qcables => [sqc]
        assert_equal 'pending', @qcable.reload.state
        assert_equal 1, @qcable.asset.wells.located_at('A2').first.aliquots.count
      end

      should 'clone the aliquots' do
        @qcable = Factory :qcable_with_asset
        @qcable_2 = @qcable.lot.qcables.create!(:qcable_creator=>@qcable.qcable_creator,:asset=>Factory(:full_plate))

        sqc = Stamp::StampQcable.new(:bed=>'1',:order=>1,:qcable=>@qcable)
        sqc_2 = Stamp::StampQcable.new(:bed=>'2',:order=>2,:qcable=>@qcable_2)
        @stamp = Factory :stamp, :stamp_qcables => [sqc,sqc_2]
        assert_equal 'pending', @qcable.reload.state
        assert_equal 1, @qcable.asset.wells.located_at('A2').first.aliquots.count
        assert_equal 'pending', @qcable_2.reload.state
        assert_equal 1, @qcable_2.asset.wells.located_at('A2').first.aliquots.count
      end
    end
  end

end
