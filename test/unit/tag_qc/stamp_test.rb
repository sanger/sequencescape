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
        @qcable = Factory :qcable
        # Unfortunately we can't do this, as stamp looks for qcables directly.
        # @qcable.expects(:do_stamp!).returns(true)
        sqc = Stamp::StampQcable.new(:bed=>'1',:order=>1,:qcable=>@qcable)
        @stamp = Factory :stamp, :stamp_qcables => [sqc]
        assert_equal 'pending', @qcable.reload.state
      end
    end
  end

end
