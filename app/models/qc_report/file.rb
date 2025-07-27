# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
class QcReport::File
  ACCEPTED_MIMETYPE = 'text/csv'
  ACCEPTED_EXTENSTION = 'csv'
  FILE_VERSION_KEY = 'Sequencescape QC Report'
  REPORT_ID_KEY = 'Report Identifier'

  # We set a maximum header size to stop really large documents from getting
  # read into the header hash.
  MAXIMUM_HEADER_SIZE = 40

  # The number of lines processed at a time.
  GROUP_SIZE = 400

  DataError = Class.new(StandardError)

  attr_reader :errors, :filename, :mime_type

  def initialize(file, set_decision, filename = nil, mime_type = ACCEPTED_MIMETYPE)
    @file = file.to_io
    @filename = filename || File.basename(file.path)
    @mime_type = mime_type
    @errors = []
    @set_decision = set_decision
  end

  # Generate a report
  def process
    @valid = true
    return false unless valid?

    ActiveRecord::Base.transaction do
      each_group_of_decisions { |group| process_group(group) }
    rescue DataError, QcMetric::InvalidValue => e
      invalid(e.message)
      raise ActiveRecord::Rollback
    end
    qc_report.proceed_decision! if @valid
    @valid
  end

  def valid? # rubocop:todo Metrics/MethodLength
    return invalid("#{filename} was not a csv file") unless is_a_csv?

    unless is_a_report?
      return (
        invalid(
          # rubocop:todo Layout/LineLength
          "#{filename} does not appear to be a qc report file. Make sure the #{FILE_VERSION_KEY} line has not been removed."
          # rubocop:enable Layout/LineLength
        )
      )
    end
    unless qc_report
      return (
        invalid(
          "Couldn't find the report #{report_identifier}. Check that the report identifier has not been modified."
        )
      )
    end

    true
  end

  # The report to which the file corresponds
  def qc_report
    @qc_report ||= QcReport.find_by(report_identifier:)
  end

  # A hash of the header section
  def headers
    @headers || parse_headers
  end

  # The report identifier in the header section
  def report_identifier
    headers[REPORT_ID_KEY]
  end

  private

  def start_line
    return @start_line unless @start_line.nil?

    parse_headers
    @start_line
  end

  # In Ruby 2.6 the CSV parser loads in multiple lines at a time, and so takes
  # the IO past the header row when we initially read in the file. Here we
  # rewind the file and seek to the correct line with several gets.
  def body_csv
    return @body_csv unless @body_csv.nil?

    header_line = start_line
    @file.rewind
    header_line.times { @file.gets }
    @body_csv = CSV.new(@file, headers: :first_row, header_converters: [:symbol])
  end

  def each_group_of_decisions
    while (group = fetch_group) && group.present?
      yield group
    end
  end

  def fetch_group
    {}.tap do |asset_collection|
      GROUP_SIZE.times do
        line = body_csv.gets
        break if line.nil?

        asset_id = line[:asset_id].strip.to_i
        asset_collection[asset_id] = process_line(line)
      end
    end
  end

  def process_group(group) # rubocop:todo Metrics/AbcSize
    asset_ids = group.keys
    assets = qc_report.qc_metrics.with_asset_ids(asset_ids)
    if asset_ids.count != assets.length
      raise DataError, "Could not find assets #{(asset_ids - assets.map(&:id)).to_sentence}"
    end

    assets.each do |metric|
      metric.human_proceed = group[metric.asset_id][:proceed]
      metric.manual_qc_decision = group[metric.asset_id][:qc_decision] if @set_decision
      metric.save!
    end
  end

  def process_line(line)
    qc_decision = (line[:qc_decision] || '').strip
    proceed = (line[:proceed] || '').strip
    { qc_decision:, proceed: }
  end

  def invalid(message)
    errors << message
    @valid = false
  end

  # We do a bit of rough-and-ready processing before passing things over to FasterCSV
  # as it should be a bit faster to capture the most common problems (ie. uploading an xls)
  # The FasterCSV read-mes even indicate that its pretty poor at handling invalid CSVs.
  def is_a_csv?
    File.extname(filename).delete('.') == ACCEPTED_EXTENSTION || mime_type == ACCEPTED_MIMETYPE
  end

  def is_a_report?
    headers[FILE_VERSION_KEY].present?
  end

  def is_header?(row)
    row.compact.present?
  end

  def parse_headers
    headers = {}
    header_parser = CSV.new(@file)
    while (row = header_parser.shift) && is_header?(row) && header_parser.lineno < MAXIMUM_HEADER_SIZE
      headers[row[0]] = (row[1] || '').strip
    end
    if header_parser.lineno >= MAXIMUM_HEADER_SIZE
      invalid('Please make sure there is an empty line before the column headers.')
    end
    @start_line = header_parser.lineno
    @headers = headers
  end
end
# rubocop:enable Metrics/ClassLength
