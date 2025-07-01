# frozen_string_literal: true

require_relative '../test_helper'

class QcMetricTest < ActiveSupport::TestCase
  context 'QcMetric' do
    should belong_to :asset
    should belong_to :qc_report

    should validate_presence_of :asset
    should validate_presence_of :qc_report
  end

  context 'A QcMetric #poor_quality_proceed' do
    [
      ['passed', true, false],
      ['passed', false, false],
      ['failed', false, false],
      ['failed', true, true],
      ['failed', nil, false],
      ['passed', nil, false],
      ['manually_passed', true, false],
      ['manually_passed', false, false],
      ['manually_failed', false, false],
      ['manually_failed', true, true],
      ['manually_failed', nil, false],
      ['manually_passed', nil, false]
    ].each do |qc_state, proceed_state, poor_quality_proceed|
      should "return #{poor_quality_proceed} when the qc_state is #{qc_state} and proceed is #{proceed_state}" do
        qc = create(:qc_metric, qc_decision: qc_state, proceed: proceed_state)
        assert_equal poor_quality_proceed, qc.poor_quality_proceed
      end
    end
  end

  context 'A QcMetric' do
    [
      ['passed', true, false],
      ['failed', true, true],
      ['manually_passed', true, false],
      ['manually_failed', true, true],
      ['unprocessable', false, true]
    ].each do |qc_state, proceedable, set_suboptimal|
      should "#{'not ' unless proceedable}allow the proceed flag to be set to Y when #{qc_state}" do
        qc = create(:qc_metric, qc_decision: qc_state)
        qc.human_proceed = 'Y'
        assert_equal proceedable, qc.proceed
      end

      should "allow the proceed flag to be set to N when #{qc_state}" do
        qc = create(:qc_metric, qc_decision: qc_state)
        qc.human_proceed = 'N'
        assert_equal false, qc.proceed
      end

      should "#{'not ' unless set_suboptimal}flag the aliquot as suboptimal when #{qc_state}" do
        aliquot = create(:aliquot)
        well = create(:well)
        well.aliquots << aliquot
        create(:qc_metric, qc_decision: qc_state, asset: well)

        # The data NEEDS to be persisted, so we reload to check this is the case.
        aliquot.reload
        assert_equal set_suboptimal, aliquot.suboptimal?
      end
    end
  end
end
