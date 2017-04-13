# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'
require 'unit/tag_qc/qcable_statemachine_checks'

class QcableTest < ActiveSupport::TestCase
  context 'A Qcable' do
    setup do
      PlateBarcode.stubs(:create).returns(OpenStruct.new(barcode: (FactoryGirl.generate :sanger_barcode)))
    end

    should belong_to :lot
    should belong_to :asset
    should belong_to :qcable_creator

    should have_one :stamp_qcable
    should have_one :stamp

    should validate_presence_of :lot
    should validate_presence_of :asset
    should validate_presence_of :qcable_creator

    # should validate_presence_of :state
    # This is handled by the state machine, which sets the default state on validate
    # This prevents up from testing it

    context '#qcable' do
      setup do
        @mock_purpose = mock('Purpose', default_state: 'created')
        @mock_purpose.expects('create!').returns(Asset.new).once
        @mock_lot = create :lot
        @mock_lot.expects(:target_purpose).returns(@mock_purpose).twice
      end

      should 'create an asset of the given purpose' do
        factory_attributes = attributes_for :qcable, lot: @mock_lot
        @qcable = Qcable.create!(factory_attributes)
        assert_equal 'created', @qcable.state
      end
    end

    context '#qcable pre-pending' do
      setup do
        @mock_purpose = build :tube_purpose, default_state: 'pending'
        @template     = FactoryGirl.build(:tag2_layout_template)
        @lot_type     = create :tag2_lot_type, target_purpose: @mock_purpose
        @mock_lot     = create :tag2_lot, lot_type: @lot_type
      end

      should 'create an asset of the given purpose' do
        # We can't use factory girl directly here, as it results in the initial state being
        # set BEFORE the lot is assigned.
        factory_attributes = attributes_for :qcable, lot: @mock_lot
        @qcable = Qcable.create!(factory_attributes)
        assert_equal @mock_purpose, @qcable.asset.purpose
        assert_equal 'pending', @qcable.state
      end
    end
  end
end
