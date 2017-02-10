# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

require 'test_helper'

class QcMetricTest < ActiveSupport::TestCase
  context 'QcMetric' do
    should belong_to :asset
    should belong_to :qc_report

    should validate_presence_of :asset
    should validate_presence_of :qc_report
  end

  context 'A QcMetric #poor_quality_proceed' do
    [
      ['passed',          true,  false],
      ['passed',          false, false],
      ['failed',          false, false],
      ['failed',          true,  true],
      ['failed',          nil,   false],
      ['passed',          nil,   false],
      ['manually_passed', true,  false],
      ['manually_passed', false, false],
      ['manually_failed', false, false],
      ['manually_failed', true,  true],
      ['manually_failed', nil,   false],
      ['manually_passed', nil,   false],
    ].each do |qc_state, proceed_state, poor_quality_proceed|
        should "return #{poor_quality_proceed} when the qc_state is #{qc_state} and proceed is #{proceed_state}" do
          qc = create :qc_metric, qc_decision: qc_state, proceed: proceed_state
          assert_equal poor_quality_proceed, qc.poor_quality_proceed
        end
    end
  end

  context 'A QcMetric' do
    [
      ['passed',         true],
      ['failed',         true],
      ['manually_passed', true],
      ['manually_failed', true],
      ['unprocessable',  false],
    ].each do |qc_state, proceedable|

      should "#{proceedable ? '' : 'not '}allow the proceed flag to be set to Y when #{qc_state}" do
        qc = create :qc_metric, qc_decision: qc_state
        qc.human_proceed = 'Y'
        assert_equal proceedable, qc.proceed
      end

      should "allow the proceed flag to be set to N when #{qc_state}" do
        qc = create :qc_metric, qc_decision: qc_state
        qc.human_proceed = 'N'
        assert_equal false, qc.proceed
      end
    end
  end
end
