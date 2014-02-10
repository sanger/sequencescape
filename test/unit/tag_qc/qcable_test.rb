require "test_helper"
require 'unit/tag_qc/qcable_statemachine_checks'

class QcableTest < ActiveSupport::TestCase
  context "A Qcable" do

    setup do
      PlateBarcode.stubs(:create).returns(OpenStruct.new(:barcode => (Factory.next :barcode)))
    end

    should_belong_to :lot
    should_belong_to :user
    should_belong_to :asset

    should_have_one :stamp_qcable
    should_have_one :stamp

    should_validate_presence_of :lot, :user, :asset

    should 'not let state be nil' do
      @qcable = Factory :qcable
      @qcable.state = nil
      assert !@qcable.valid?
    end

    context "#qcable" do
      setup do
        @mock_purpose = mock('Purpose')
        @mock_purpose.expects('create!').returns(Asset.new).once
        @mock_lot     = Factory :lot
        @mock_lot.expects(:target_purpose).returns(@mock_purpose).once
      end

      should "create an asset of the given purpose" do
        @qcable       = Factory :qcable, :lot => @mock_lot
      end

    end
  end

end
