# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class QcDecisionTest < ActiveSupport::TestCase
  context 'QcDecision' do
    should belong_to :user
    should belong_to :lot

    should have_many :qcables

    should validate_presence_of :user

    context '#qc_decision' do
      setup do
        @lot = create :lot
        @user = create :user
        @user.roles.create!(name: 'qa_manager')
        @user_b = create :user
        @qcable_a = create :qcable, lot: @lot, state: 'pending'
        @qcable_b = create :qcable, lot: @lot, state: 'pending'
      end

      context 'with valid data' do
        setup do
          @qcd = QcDecision.create(
            user: @user,
            lot: @lot,
            decisions: [
              { qcable: @qcable_a, decision: 'release' },
              { qcable: @qcable_b, decision: 'fail' }
            ]
          )
        end

        should 'Update the QC state' do
          assert_equal 'available', @qcable_a.state
          assert_equal 'failed', @qcable_b.state
        end

        should 'record the decision' do
          assert_equal 2, @qcd.qc_decision_qcables.count
          assert_equal ['fail', 'release'], @qcd.qc_decision_qcables.map { |d| d.decision }.sort
        end
      end

      should 'reject invalid state transitions' do
        assert_raise ActiveRecord::RecordInvalid do
          QcDecision.create!(
            user: @user,
            lot: @lot,
            decisions: [
              { qcable: @qcable_a, decision: 'delete' },
              { qcable: @qcable_b, decision: 'fail' }
            ]
          )
        end
      end

      should 'reject invalid users' do
        assert_raise ActiveRecord::RecordInvalid do
          QcDecision.create!(
            user: @user_b,
            lot: @lot,
            decisions: [
              { qcable: @qcable_a, decision: 'release' },
              { qcable: @qcable_b, decision: 'fail' }
            ]
          )
        end
      end
    end
  end
end
