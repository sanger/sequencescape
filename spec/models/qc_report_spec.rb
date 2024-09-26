# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QcReport do
  it 'is not valid without a study' do
    expect(build(:qc_report, study: nil)).not_to be_valid
  end

  it 'is not valid without a product criteria' do
    expect(build(:qc_report, product_criteria: nil)).not_to be_valid
  end

  context 'include existing' do
    attr_reader :study, :other_study, :stock_plate, :qc_report, :qc_metric_count

    before do
      @study = create(:study)
      @other_study = create(:study)
      @stock_plate = create(:plate, purpose: PlatePurpose.find_or_create_by(name: 'Stock plate'))

      [@study, @other_study].each do |study|
        2.times do |i|
          attribute = create(:well_attribute, current_volume: 500, concentration: 200)
          sample = create(:study_sample, study:).sample
          sample.update!(sanger_sample_id: 'TEST1')
          well =
            create(:well,
                   samples: [sample],
                   plate: stock_plate,
                   map: create(:map, location_id: i),
                   well_attribute: attribute)
          well.aliquots.each { |a| a.update!(study:) }
        end
      end

      @qc_report = create(:qc_report, study: @study)
      @qc_metric_count = QcMetric.count
      Delayed::Worker.new.work_off
    end

    it 'generates qc_metrics per sample' do
      expect(QcMetric.count - qc_metric_count).to eq(2)
      expect(qc_report.qc_metrics.count).to eq(2)
    end

    it 'assigns a report identifier' do
      expect(qc_report.report_identifier).to be_present
      expect(qc_report.report_identifier).to match(/wtccc_product[0-9]+_[0-9]{12}/)
    end

    it 'records the result of each qc' do
      qc_report.qc_metrics.each do |metric|
        expect(metric.qc_decision).to eq('passed')
        expect(metric.proceed).to be_nil
        expect(metric.metrics).to eq(total_micrograms: 100, comment: '', sanger_sample_id: 'TEST1')
      end
    end
  end

  context 'excluding existing' do
    attr_reader :study,
                :stock_plate,
                :current_criteria,
                :other_criteria,
                :matching_report,
                :other_report,
                :attribute,
                :qc_report,
                :qc_metric_count,
                :qc_report,
                :unreported_sample,
                :other_reported_sample

    before do
      @study = create(:study)
      @stock_plate = create(:plate, purpose: PlatePurpose.find_or_create_by(name: 'Stock plate'))

      @current_criteria = create(:product_criteria)
      @other_criteria = create(:product_criteria)

      @matching_report =
        create(:qc_report,
               study:,
               exclude_existing: true,
               product_criteria: current_criteria,
               report_identifier: 'Override')
      @other_report = create(:qc_report, study:, exclude_existing: true, product_criteria: other_criteria)

      @attribute = create(:well_attribute, current_volume: 500, concentration: 200)

      sample = create(:study_sample, study:).sample
      @unreported_sample =
        well =
          create(:well,
                 samples: [sample],
                 plate: stock_plate,
                 map: create(:map, location_id: 1),
                 well_attribute: attribute)
      well.aliquots.each { |a| a.update!(study:) }

      sample = create(:study_sample, study:).sample
      well =
        create(:well,
               samples: [sample],
               plate: stock_plate,
               map: create(:map, location_id: 2),
               well_attribute: attribute)
      well.aliquots.each { |a| a.update!(study:) }
      create(:qc_metric, asset: well, qc_report: matching_report)

      sample = create(:study_sample, study:).sample
      @other_reported_sample =
        well =
          create(:well,
                 samples: [sample],
                 plate: stock_plate,
                 map: create(:map, location_id: 3),
                 well_attribute: attribute)
      well.aliquots.each { |a| a.update!(study:) }
      create(:qc_metric, asset: well, qc_report: other_report)

      sample = create(:study_sample, study:).sample
      well =
        create(:well,
               samples: [sample],
               plate: stock_plate,
               map: create(:map, location_id: 4),
               well_attribute: attribute)
      well.aliquots.each { |a| a.update!(study:) }
      create(:qc_metric, asset: well, qc_report: matching_report)
      create(:qc_metric, asset: well, qc_report: other_report)

      @qc_report = create(:qc_report, study:, exclude_existing: true, product_criteria: current_criteria)
      @qc_metric_count = QcMetric.count
      qc_report.generate!
    end

    it 'generates qc_metrics per sample which needs them' do
      expect(QcMetric.count - qc_metric_count).to eq(2)
      expect(qc_report.qc_metrics.count).to eq(2)
      expect(qc_report.qc_metrics.map(&:asset)).to include(unreported_sample)
      expect(qc_report.qc_metrics.map(&:asset)).to include(other_reported_sample)
    end
  end

  context 'QcReport state machine' do
    let!(:qc_report) { create(:qc_report) }

    before { allow(qc_report).to receive(:generate_report) }

    it 'follows expected state machine' do
      expect(qc_report.state).to eq('queued')
      qc_report.generate!
      expect(qc_report.state).to eq('generating')
      qc_report.generation_complete!
      expect(qc_report.state).to eq('awaiting_proceed')
      qc_report.proceed_decision!
      expect(qc_report.state).to eq('complete')
    end
  end

  context 'limit by plate purposes' do
    attr_reader :qc_report

    let!(:study) { create(:study) }
    let(:plate_purposes) { create_list(:plate_purpose, 3) }
    let(:plate_purpose_names) { plate_purposes.map(&:name) }

    before do
      create(:well_for_qc_report, study:, plate: create(:plate, plate_purpose: plate_purposes[0]))
      create(:well_for_qc_report, study:, plate: create(:plate, plate_purpose: plate_purposes[1]))
      create(:well_for_qc_report, study:, plate: create(:plate, plate_purpose: plate_purposes[2]))

      @qc_report =
        create(:qc_report,
               study:,
               exclude_existing: false,
               product_criteria: create(:product_criteria),
               plate_purposes: plate_purpose_names)
      qc_report.generate!
    end

    it 'generates qc_metrics per sample which needs them' do
      expect(qc_report.qc_metrics.count).to eq(3)
    end
  end
end
