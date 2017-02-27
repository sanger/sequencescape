# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

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
    @file = file
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
      begin
        each_group_of_decisions do |group|
          process_group(group)
        end
      rescue DataError, QcMetric::InvalidValue => exception
        invalid(exception.message)
        raise ActiveRecord::Rollback
      end
    end
    qc_report.proceed_decision! if @valid
    @valid
  end

  def valid?
    return invalid("#{filename} was not a csv file") unless is_a_csv?
    return invalid("#{filename} does not appear to be a qc report file. Make sure the #{FILE_VERSION_KEY} line has not been removed.") unless is_a_report?
    return invalid("Couldn't find the report #{report_identifier}. Check that the report identifier has not been modified.") unless qc_report
    true
  end

  # The report to which the file corresponds
  def qc_report
    @qc_report ||= QcReport.find_by(report_identifier: report_identifier)
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

  # This should ONLY be called after the headers have been read out.
  # This puts the column headers at the top of the remaining csv file
  def body_csv
    @body_csv ||= CSV.new(@file, headers: :first_row, header_converters: [:symbol])
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

  def process_group(group)
    asset_ids = group.keys
    assets = qc_report.qc_metrics.with_asset_ids(asset_ids)
    raise DataError, "Could not find assets #{(asset_ids - assets.map(&:id)).to_sentence}" if asset_ids.count != assets.length
    assets.each do |metric|
      metric.human_proceed = group[metric.asset_id][:proceed]
      metric.manual_qc_decision = group[metric.asset_id][:qc_decision] if @set_decision
      metric.save!
    end
  end

  def process_line(line)
    qc_decision = (line[:qc_decision] || '').strip
    proceed = (line[:proceed] || '').strip
    { qc_decision: qc_decision, proceed: proceed }
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
    lines_read = 0
    while (row = header_parser.shift) && is_header?(row) && lines_read < MAXIMUM_HEADER_SIZE
      headers[row[0]] = (row[1] || '').strip
      lines_read += 1
    end
    invalid('Please make sure there is an empty line before the column headers.') if lines_read >= MAXIMUM_HEADER_SIZE
    @headers = headers
  end
end
