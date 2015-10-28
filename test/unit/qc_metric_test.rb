#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"

class QcMetricTest < ActiveSupport::TestCase

  context "QcMetric" do

    should_belong_to :asset, :qc_report

    should_validate_presence_of :asset, :qc_report

  end

  context "A QcMetric" do

    [
      [ true,  true,  false ],
      [ true,  false, false ],
      [ false, false, false ],
      [ false, true,  true  ],
      [ false, nil,   false ],
      [ true,  nil,   false ],
    ].each do |qc_state,proceed_state,poor_quality_proceed|
        should "return #{poor_quality_proceed.to_s} when the qc_state is #{qc_state.to_s} and proceed is #{proceed_state.to_s}" do
          qc = Factory :qc_metric, :qc_decision => qc_state, :proceed => proceed_state
          assert_equal poor_quality_proceed, qc.poor_quality_proceed
        end
      end
  end
end
