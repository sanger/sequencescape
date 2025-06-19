# frozen_string_literal: true

require 'test_helper'
require 'timecop'
require 'csv'

class QcReport::FileTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  context 'QcReport File' do
    context 'given a non-csv file' do
      setup do
        @file = fixture_file_upload("#{Rails.root}/test/data/190_tube_sample_info.xls", 'text/csv')
        @qcr_file = QcReport::File.new(@file, false, '190_tube_sample_info.xls', 'application/excel')
      end

      should 'fail processing' do
        assert_equal false, @qcr_file.process, 'Non-csv file processed unexpectedly'
        assert_equal ['190_tube_sample_info.xls was not a csv file'], @qcr_file.errors
      end

      teardown { @file.close unless @file.nil? }
    end

    context 'given a non-compatible csv file' do
      setup do
        @file = fixture_file_upload("#{Rails.root}/test/data/fluidigm.csv", 'text/csv')
        @qcr_file = QcReport::File.new(@file, false, 'fluidigm.csv', 'text/csv')
      end

      should 'fail processing' do
        assert_equal false, @qcr_file.process, 'Non-compatible file processed unexpectedly'
        assert_equal [
          # rubocop:todo Layout/LineLength
          'fluidigm.csv does not appear to be a qc report file. Make sure the Sequencescape QC Report line has not been removed.'
          # rubocop:enable Layout/LineLength
        ],
                     @qcr_file.errors
      end

      teardown { @file.close unless @file.nil? }
    end

    context 'given a file with no report' do
      setup do
        @file = fixture_file_upload("#{Rails.root}/test/data/qc_report.csv", 'text/csv')
        @qcr_file = QcReport::File.new(@file, false)
      end

      should 'fail processing' do
        assert_equal false, @qcr_file.process, 'File with no report processed unexpectedly'
        assert_equal [
          # rubocop:todo Layout/LineLength
          "Couldn't find the report wtccc_demo_product_20150101000000. Check that the report identifier has not been modified."
          # rubocop:enable Layout/LineLength
        ],
                     @qcr_file.errors
      end

      teardown { @file.close unless @file.nil? }
    end

    context 'given a file with a report' do
      setup do
        @product = create(:product, name: 'Demo Product')
        @criteria = create(:product_criteria, product: @product, version: 1)
        @study = create(:study, name: 'Example study')
        Timecop.freeze(DateTime.parse('01/01/2015')) do
          @report =
            create(
              :qc_report,
              study: @study,
              exclude_existing: false,
              product_criteria: @criteria,
              state: 'awaiting_proceed'
            )
        end
        @asset_ids = []
        2.times do |i|
          create(:qc_metric, qc_report: @report, qc_decision: %w[passed failed][i], asset: create(:well, id: i + 1))
        end
        @file = fixture_file_upload("#{Rails.root}/test/data/qc_report.csv", 'text/csv')

        @qcr_file = QcReport::File.new(@file, false, 'qc_report.csv', 'text/csv')
      end

      should 'pass processing' do
        assert_equal true, @qcr_file.process, 'Processing failed unexpectedly'
        assert_equal [], @qcr_file.errors
      end

      should 'complete the report and set the proceed flags' do
        @qcr_file.process
        @report.reload
        assert_equal 'complete', @report.state
        assert @report.qc_metrics.all?(&:proceed), 'Not all metrics are proceed'
      end

      should 'not adjust the qc_decision flag' do
        @qcr_file.process
        assert_equal %w[passed failed], @report.qc_metrics.order('asset_id ASC').map(&:qc_decision)
      end

      teardown { @file.close unless @file.nil? }
    end

    context 'On overriding' do
      setup do
        @product = FactoryBot.build(:product, name: 'Demo Product')
        @criteria = FactoryBot.build(:product_criteria, product: @product, version: 1)
        @study = FactoryBot.build(:study, name: 'Example study')
        Timecop.freeze(DateTime.parse('01/01/2015')) do
          @report =
            create(
              :qc_report,
              study: @study,
              exclude_existing: false,
              product_criteria: @criteria,
              state: 'awaiting_proceed'
            )
        end
        @asset_ids = []
        2.times do |i|
          m = create(:qc_metric, qc_report: @report, qc_decision: %w[passed failed][i], asset: create(:well, id: i + 1))
          @asset_ids << m.asset_id
        end
        @file = fixture_file_upload("#{Rails.root}/test/data/qc_report.csv", 'text/csv')

        @qcr_file = QcReport::File.new(@file, true, 'qc_report.csv', 'text/csv')
      end

      should 'adjust the qc_decision flag' do
        @qcr_file.process
        assert_equal %w[passed manually_passed], @report.qc_metrics.order(:asset_id).map(&:qc_decision)
      end

      teardown { @file.close unless @file.nil? }
    end

    context 'With missing assets' do
      setup do
        @product = FactoryBot.build(:product, name: 'Demo Product')
        @criteria = FactoryBot.build(:product_criteria, product: @product, version: 1)
        @study = FactoryBot.build(:study, name: 'Example study')
        Timecop.freeze(DateTime.parse('01/01/2015')) do
          @report =
            create(
              :qc_report,
              study: @study,
              exclude_existing: false,
              product_criteria: @criteria,
              state: 'awaiting_proceed'
            )
        end
        @asset_ids = []
        2.times { |i| create(:qc_metric, qc_report: @report, qc_decision: %w[passed failed][i]) }
        @file = fixture_file_upload("#{Rails.root}/test/data/qc_report.csv", 'text/csv')

        @qcr_file = QcReport::File.new(@file, true, 'qc_report.csv', 'text/csv')
      end

      should 'adjust the qc_decision flag' do
        assert_equal false, @qcr_file.process
        assert_equal ['Could not find assets 1 and 2'], @qcr_file.errors
      end

      teardown { @file.close unless @file.nil? }
    end
  end
end
