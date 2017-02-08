# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class SequencingQcBatchTest < ActiveSupport::TestCase
  STATES = %w(qc_pending qc_submitted qc_manual qc_manual_in_progress qc_completed)

  context SequencingQcBatch do
    context '.included' do
      should 'setup the appropriate behaviour' do
        batch = Class.new

        batch.expects(:validates_inclusion_of).with(:qc_state, in: STATES, allow_blank: true)
        batch.expects(:belongs_to).with(:qc_pipeline, class_name: 'Pipeline')
        batch.expects(:before_create).with(:qc_pipeline_update)

        batch.send(:include, SequencingQcBatch)
      end
    end

    setup do
      @batch = Object.new
      @batch.extend(SequencingQcBatch) # Avoids the self.included callback
    end

    context '#qc_states' do
      should 'return the appropriate states' do
        assert_equal STATES, @batch.qc_states
      end
    end

    context '#qc_submitted' do
      should 'moves to the next state when it is not nil' do
        @batch.expects(:qc_next_state).twice.returns('qc_fooing')
        @batch.expects(:update_attribute).with(:qc_state, 'qc_fooing')
        @batch.qc_submitted
      end

      should 'do nothing if the next state is nil' do
        @batch.stubs(:qc_next_state).returns(nil)
        @batch.qc_submitted
      end
    end

    context '#qc_criteria_received' do
      should 'moves to the next state when it is not nil' do
        @batch.expects(:qc_next_state).twice.returns('qc_fooing')
        @batch.expects(:update_attribute).with(:qc_state, 'qc_fooing')
        @batch.qc_criteria_received
      end

      should 'do nothing if the next state is nil' do
        @batch.stubs(:qc_next_state).returns(nil)
        @batch.qc_criteria_received
      end
    end

    context '#qc_complete' do
      should 'moves to the next state when it is not nil' do
        @batch.expects(:qc_next_state).twice.returns('qc_fooing')
        @batch.expects(:update_attribute).with(:qc_state, 'qc_fooing')
        @batch.qc_complete
      end

      should 'do nothing if the next state is nil' do
        @batch.stubs(:qc_next_state).returns(nil)
        @batch.qc_complete
      end
    end

    context '#processing_in_manual_qc?' do
      should 'return true if current state is "qc_manual_in_progress"' do
        @batch.stubs(:qc_state).returns('qc_manual_in_progress')
        assert @batch.processing_in_manual_qc?
      end

      should 'return true if current state is "qc_manual"' do
        @batch.stubs(:qc_state).returns('qc_manual')
        assert @batch.processing_in_manual_qc?
      end

      should 'return false if the state is not manual QC' do
        @batch.stubs(:qc_state).returns('qc_completed')
        assert !@batch.processing_in_manual_qc?
      end
    end

    context '#qc_next_state' do
      should 'raise an error if the current state is invalid' do
        @batch.stubs(:qc_state).returns('I AM WELL BROKEN')
        assert_raises(StandardError) { @batch.qc_next_state }
      end

      should 'return nil if the current state is the last one' do
        @batch.stubs(:qc_state).returns(STATES.last)
        assert_nil @batch.qc_next_state
      end

      STATES[0..-2].each_with_index do |current_state, index|
        next_state = STATES[index + 1]
        should "return '#{next_state}' for current state of '#{current_state}'" do
          @batch.stubs(:qc_state).returns(current_state)
          assert_equal next_state, @batch.qc_next_state
        end
      end
    end

    context '#qc_previous_state' do
      should 'raise an error if the current state is invalid' do
        @batch.stubs(:qc_state).returns('I AM WELL BROKEN')
        assert_raises(StandardError) { @batch.qc_previous_state }
      end

      should 'return nil if the current state is the first one' do
        @batch.stubs(:qc_state).returns(STATES.first)
        assert_nil @batch.qc_previous_state
      end

      STATES[0..-2].each_with_index do |previous_state, index|
        current_state = STATES[index + 1]
        should "return '#{previous_state}' for current state of '#{current_state}'" do
          @batch.stubs(:qc_state).returns(current_state)
          assert_equal previous_state, @batch.qc_previous_state
        end
      end
    end
  end
end
