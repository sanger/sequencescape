# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015,2016 Genome Research Ltd.

require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class TransferRequestTest < ActiveSupport::TestCase
  def shared_setup
    @source = LibraryTube.create!.tap { |tube| tube.aliquots.create!(sample: create(:sample)) }
    create(:tag).tag!(@source)
    @destination = LibraryTube.create!
  end

  def self.shared_tests
    should 'duplicate the aliquots' do
      expected_aliquots = @source.aliquots.map { |a| [a.sample_id, a.tag_id] }
      target_aliquots   = @destination.aliquots.map { |a| [a.sample_id, a.tag_id] }
      assert_equal(expected_aliquots, target_aliquots)
    end

    should 'have the correct attributes' do
      assert @transfer_request.request_type == RequestType.find_by(key: 'transfer')
      assert @transfer_request.sti_type == 'TransferRequest'
      assert @transfer_request.state == 'pending'
      assert @transfer_request.asset_id == @source.id
      assert @transfer_request.target_asset_id == @destination.id
    end
  end

  context 'TransferRequest' do
    context 'when using the constuctor' do
      setup do
        shared_setup
        @transfer_request = RequestType.transfer.create!(asset: @source, target_asset: @destination)
      end

      shared_tests
    end

    should 'not permit transfers to the same asset' do
      asset = create(:sample_tube)
      assert_raises(ActiveRecord::RecordInvalid) { RequestType.transfer.create!(asset: asset, target_asset: asset) }
    end

    context 'with a tag clash' do
      setup do
        tag = create :tag
        tag2 = create :tag
        @aliquot_1 = create :aliquot, tag: tag, tag2: tag2, receptacle: create(:well)
        @aliquot_2 = create :aliquot, tag: tag, tag2: tag2, receptacle: create(:well)

        @target_asset = create :well
      end

      should 'raise an exception' do
        @transfer_request = RequestType.transfer.create!(asset: @aliquot_1.receptacle.reload, target_asset: @target_asset)
        assert_raise Aliquot::TagClash do
          @transfer_request = RequestType.transfer.create!(asset: @aliquot_2.receptacle.reload, target_asset: @target_asset)
        end
      end
    end
  end

  extend IlluminaB::RequestStatemachineChecks

  state_machine(TransferRequest) do
    check_event(:start!, :pending)
    check_event(:pass!, :pending, :started, :failed)
    check_event(:qc!, :passed)
    check_event(:fail!, :pending, :started, :passed)
    check_event(:cancel!, :started, :passed, :qc_complete)
    check_event(:cancel_before_started!, :pending)
  end
end
