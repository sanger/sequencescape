# frozen_string_literal: true

require 'test_helper'

class OwnerTest < ActionController::TestCase
  context 'Plates' do
    setup do
      @barcode_printer = mock('printer abc')
      @barcode_printer.stubs(:id).returns(1)
      @barcode_printer.stubs(:name).returns('abc')
      @barcode_printer.stubs(:print_labels).returns(nil)
      @barcode_printer.stubs(:map).returns(['abc', 1])
      @barcode_printer.stubs(:first).returns(@barcode_printer)
      BarcodePrinter.stubs(:find).returns(@barcode_printer)
      PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))
      @barcode_printer.stubs(:each).returns(@barcode_printer)
      @barcode_printer.stubs(:blank?).returns(true)

      @user = create(:user)
      @parent_plate = create(:plate)

      @pc_event = PlateCreation.create(user: @user, parent: @parent_plate, child_purpose: create(:plate_purpose))
      @child_plate = @pc_event.child
    end

    should 'have owners after creation' do
      assert_equal @child_plate.owner, @user
      assert_equal @child_plate.plate_owner.eventable, @pc_event
    end

    should 'be updated when stuff happens' do
      @user2 = create(:user)
      @tf_event =
        Transfer::BetweenPlates.create!(
          source: @parent_plate,
          destination: @child_plate,
          user: @user2,
          transfers: {
            'A1' => 'A1'
          }
        )
      assert_equal @child_plate.owner, @user2
      assert_equal @child_plate.plate_owner.eventable, @tf_event
    end
  end
end
