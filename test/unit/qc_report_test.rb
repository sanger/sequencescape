#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"

class QcReportTest < ActiveSupport::TestCase

  context "QcReport" do

    should_belong_to :study, :product_criteria
    should_have_many :qc_metrics
    should_validate_presence_of :study, :product_criteria
    # Also validates state, but we leave that off here as the state machine auto-populates it

  end

  context "A QcReport" do

    setup do
      @study = Factory :study
      @stock_plate = Factory :plate
      2.times do |i|
        @attribute = Factory :well_attribute, :measured_volume => 500, :concentration => 200
        sample = Factory(:study_sample, :study => @study).sample
        well = Factory :well, :samples => [sample], :plate => @stock_plate, :map => Factory(:map, :location_id => i), :well_attribute => @attribute
      end

      @qc_report = Factory :qc_report, :study => @study
      @qc_metric_count = QcMetric.count
      @qc_report.generate!
    end

    should 'generate qc_metrics per sample' do
      assert_equal 2, QcMetric.count - @qc_metric_count
      assert_equal 2, @qc_report.qc_metrics.count
    end

    should 'assign a report identifier' do
      assert @qc_report.report_identifier.present?, "No identifier assigned"
      assert /wtccc_product[0-9]+_[0-9]{12}/ === @qc_report.report_identifier, "Unexpected identifier: #{@qc_report.report_identifier}"
    end

    should 'record the result of each qc' do
      @qc_report.qc_metrics.each do |metric|
        assert_equal true, metric.qc_decision, "Metric had a qc_decision of #{metric.qc_decision} not true"
        assert_equal nil, metric.proceed
        assert_equal({
          :total_micrograms => 100,
          :comment => ''
        }, metric.metrics)
      end
    end
  end

  context "QcReport state machine" do

    setup do
      @qc_report = Factory :qc_report
      # Stub out report generation as it advances the state machine
      @qc_report.stubs(:generate_report)
    end

    should 'follow expected state machine' do
      assert_equal 'queued', @qc_report.state
      @qc_report.generate!
      assert_equal 'generating', @qc_report.state
      @qc_report.generation_complete!
      assert_equal 'awaiting_proceed', @qc_report.state
      @qc_report.proceed_decision!
      assert_equal 'complete', @qc_report.state
    end
  end
end
