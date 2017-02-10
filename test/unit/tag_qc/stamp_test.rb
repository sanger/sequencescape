# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class StampTest < ActiveSupport::TestCase
  context 'A Stamp' do
    should belong_to :user
    should belong_to :robot
    should belong_to :lot

    should have_many :qcables
    should have_many :stamp_qcables

    should validate_presence_of :tip_lot
    should validate_presence_of :user
    should validate_presence_of :robot
    should validate_presence_of :lot

    context '#stamp' do
      should 'transition qcables to pending' do
        @qcable = create :qcable_with_asset
        # Unfortunately we can't do this, as stamp looks for qcables directly.
        # @qcable.expects(:do_stamp!).returns(true)
        sqc = Stamp::StampQcable.new(bed: '1', order: 1, qcable: @qcable)
        @stamp = create :stamp, stamp_qcables: [sqc]
        assert_equal 'pending', @qcable.reload.state
      end

      should 'transfer samples' do
        @qcable = create :qcable_with_asset
        # Unfortunately we can't do this, as stamp looks for qcables directly.
        # @qcable.expects(:do_stamp!).returns(true)

        sqc = Stamp::StampQcable.new(bed: '1', order: 1, qcable: @qcable)
        @stamp = create :stamp, stamp_qcables: [sqc]
        assert_equal 'pending', @qcable.reload.state
        assert_equal 1, @qcable.asset.wells.located_at('A2').first.aliquots.count
      end

      should 'clone the aliquots' do
        @qcable = create :qcable_with_asset, state: 'created'
        @qcable_2 = @qcable.lot.qcables.create!(qcable_creator: @qcable.qcable_creator, asset: create(:full_plate), state: 'created')

        sqc = Stamp::StampQcable.new(bed: '1', order: 1, qcable: @qcable)
        sqc_2 = Stamp::StampQcable.new(bed: '2', order: 2, qcable: @qcable_2)
        @stamp = create :stamp, stamp_qcables: [sqc, sqc_2]
        assert_equal 'pending', @qcable.reload.state
        assert_equal 1, @qcable.asset.wells.located_at('A2').first.aliquots.count
        assert_equal 'pending', @qcable_2.reload.state
        assert_equal 1, @qcable_2.asset.wells.located_at('A2').first.aliquots.count
      end
    end
  end
end
