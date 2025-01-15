# frozen_string_literal: true
class Presenters::QcReportPresenter
  REPORT_IDENTITY = 'Sequencescape QC Report'
  VERSION = '1.0.0'
  HEADER_FIELDS = {
    'Study' => :study_name,
    'Product' => :product_name,
    'Criteria Version' => :criteria_version,
    'Report Identifier' => :report_identifier,
    'Generated on' => :created_date,
    'Contents' => :new_or_all
  }.freeze

  attr_reader :qc_report, :queue_count

  def initialize(qc_report, queue_count = 0)
    @qc_report = qc_report
    @queue_count = queue_count
  end

  def filename
    "#{report_identifier}.csv"
  end

  def criteria_version
    "#{qc_report.product_criteria.stage}_#{qc_report.product_criteria.version}"
  end

  def product_name
    qc_report.product.name
  end

  def study_name
    qc_report.study.name
  end

  def study_abbreviation
    qc_report.study.abbreviation
  end

  def state
    qc_report.state.humanize
  end

  def new_or_all
    qc_report.exclude_existing ? 'New samples' : 'All samples'
  end

  def created_date
    qc_report.created_at.to_fs(:rfc822)
  end

  def state_description
    I18n.t(qc_report.state, scope: 'qc_reports.state_descriptions', default: :default, queue_count: queue_count)
  end

  def to_csv(io)
    @csv = CSV.new(io)
    csv_headers
    @csv << [] # Pad with an empty line
    csv_field_headers
    csv_body
    @csv
  end

  delegate :available?, :study, :report_identifier, to: :qc_report

  def each_header
    HEADER_FIELDS.each { |field, lookup| yield [field, send(lookup)] }
  end

  private

  # Information about the qc_report itself
  def csv_headers
    @csv << [REPORT_IDENTITY, VERSION]
    @csv << [I18n.t('qc_reports.fixed_content')]
    @csv << [I18n.t('qc_reports.instruction')]
    each_header { |pair| @csv << pair }
  end

  def criteria_headers
    @criteria_headers ||= qc_report.product_criteria.headers
  end

  # The headers for the qc information table
  def csv_field_headers
    @csv << (['Asset ID'] + criteria_headers.map { |h| h.to_s.humanize } + ['Qc Decision', 'Proceed'])
  end

  def csv_body
    qc_report.qc_metrics.each do |m|
      @csv << ([m.asset_id] + criteria_headers.map { |h| m.metrics[h] } + [m.qc_decision, m.human_proceed])
    end
  end
end
