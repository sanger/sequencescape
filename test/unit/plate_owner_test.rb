# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

require 'test_helper'
require 'users_controller'

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
      PlateBarcode.stubs(:create).returns(OpenStruct.new(barcode: '1234567'))
      @barcode_printer.stubs(:each).returns(@barcode_printer)
      @barcode_printer.stubs(:blank?).returns(true)

      @user = create :user
      @parent_plate_purpose = create :parent_plate_purpose
      @parent_plate = create :plate, purpose: @parent_plate_purpose

      @pc_event = PlateCreation.create(
        user: @user,
        parent: @parent_plate,
        child_purpose: @parent_plate_purpose.child_purposes.first
      )
      @child_plate = @pc_event.child
    end

    should 'have owners after creation' do
      assert_equal @child_plate.owner, @user
      assert_equal @child_plate.plate_owner.eventable, @pc_event
    end

    should 'be updated when stuff happens' do
      @user2 = create :user
      @tf_event = Transfer::BetweenPlates.create!(source: @parent_plate, destination: @child_plate, user: @user2, transfers: { 'A1' => 'A1' })
      assert_equal @child_plate.owner, @user2
      assert_equal @child_plate.plate_owner.eventable, @tf_event
    end
  end
end
