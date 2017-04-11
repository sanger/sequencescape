# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

require 'test_helper'

class QcReportTest < ActiveSupport::TestCase
  context 'QcReport' do
    should belong_to :study
    should belong_to :product_criteria
    should have_many :qc_metrics
    should validate_presence_of :study
    should validate_presence_of :product_criteria
    # Also validates state, but we leave that off here as the state machine auto-populates it
  end

  context 'A QcReport' do
    context 'including existing' do
      setup do
        @study = create :study
        @other_study = create :study
        @stock_plate = create :plate, purpose: PlatePurpose.find_or_create_by(name: 'Stock plate')

        [@study, @other_study].each do |study|
          2.times do |i|
            attribute = create :well_attribute, current_volume: 500, concentration: 200
            sample = create(:study_sample, study: study).sample
            sample.update_attributes!(sanger_sample_id: 'TEST1')
            well = create :well, samples: [sample], plate: @stock_plate, map: create(:map, location_id: i), well_attribute: attribute
            well.aliquots.each { |a| a.update_attributes!(study: study) }
          end
        end

        @qc_report = create :qc_report, study: @study
        @qc_metric_count = QcMetric.count
        Delayed::Worker.new.work_off
      end

      should 'generate qc_metrics per sample' do
        assert_equal 2, QcMetric.count - @qc_metric_count
        assert_equal 2, @qc_report.qc_metrics.count
      end

      should 'assign a report identifier' do
        assert @qc_report.report_identifier.present?, 'No identifier assigned'
        assert_match(/wtccc_product[0-9]+_[0-9]{12}/, @qc_report.report_identifier, "Unexpected identifier: #{@qc_report.report_identifier}")
      end

      should 'record the result of each qc' do
        @qc_report.qc_metrics.each do |metric|
          assert_equal 'passed', metric.qc_decision
          assert_equal nil, metric.proceed
          assert_equal({
            total_micrograms: 100,
            comment: '',
            sanger_sample_id: 'TEST1'
          }, metric.metrics)
        end
      end
    end

    context 'excluding existing' do
      setup do
        @study = create :study
        @stock_plate = create :plate, purpose: PlatePurpose.find_or_create_by(name: 'Stock plate')

        @current_criteria = create :product_criteria
        @other_criteria = create :product_criteria

        @matching_report = create :qc_report, study: @study, exclude_existing: true, product_criteria: @current_criteria, report_identifier: 'Override'
        @other_report = create :qc_report, study: @study, exclude_existing: true, product_criteria: @other_criteria

        @attribute = create :well_attribute, current_volume: 500, concentration: 200

        sample = create(:study_sample, study: @study).sample
        @unreported_sample = well = create :well, samples: [sample], plate: @stock_plate, map: create(:map, location_id: 1), well_attribute: @attribute
        well.aliquots.each { |a| a.update_attributes!(study: @study) }

        sample = create(:study_sample, study: @study).sample
        well = create :well, samples: [sample], plate: @stock_plate, map: create(:map, location_id: 2), well_attribute: @attribute
        well.aliquots.each { |a| a.update_attributes!(study: @study) }
        create :qc_metric, asset: well, qc_report: @matching_report

        sample = create(:study_sample, study: @study).sample
        @other_reported_sample = well = create :well, samples: [sample], plate: @stock_plate, map: create(:map, location_id: 3), well_attribute: @attribute
        well.aliquots.each { |a| a.update_attributes!(study: @study) }
        create :qc_metric, asset: well, qc_report: @other_report

        sample = create(:study_sample, study: @study).sample
        well = create :well, samples: [sample], plate: @stock_plate, map: create(:map, location_id: 4), well_attribute: @attribute
        well.aliquots.each { |a| a.update_attributes!(study: @study) }
        create :qc_metric, asset: well, qc_report: @matching_report
        create :qc_metric, asset: well, qc_report: @other_report

        @qc_report = create :qc_report, study: @study, exclude_existing: true, product_criteria: @current_criteria
        @qc_metric_count = QcMetric.count
        @qc_report.generate!
      end

      should 'generate qc_metrics per sample which needs them' do
        assert_equal 2, QcMetric.count - @qc_metric_count
        assert_equal 2, @qc_report.qc_metrics.count
        assert_includes @qc_report.qc_metrics.map(&:asset), @unreported_sample
        assert_includes @qc_report.qc_metrics.map(&:asset), @other_reported_sample
      end
    end
  end

  context 'QcReport state machine' do
    setup do
      @qc_report = create :qc_report
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
