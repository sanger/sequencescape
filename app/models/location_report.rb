# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

class LocationReport < ApplicationRecord
  extend DbFile::Uploader

  attr_accessor :barcodes_list

  def barcodes_text
    barcodes_list.join(' ') unless @barcodes_list.nil?
  end

  def barcodes_text=(value)
    self.barcodes_list = if value.nil?
                           nil
                         else
                           value.strip.split(/[\s]+/)
                         end
  end

  self.per_page = 10

  scope :for_user, ->(user) { where(user_id: user.id) }

  belongs_to :study
  belongs_to :user

  has_uploaded :report, serialization_column: 'report_filename'

  def headers
    %w[Barcode HumanBarcode Type Created Location Service Study Owner]
  end

  def generate!
    ActiveRecord::Base.transaction do
      csv_options = { row_sep: "\r\n", force_quotes: true }
      filename    = "location_report_#{name}.csv"
      Tempfile.open(filename) do |tempfile|
        generate_report_rows do |fields|
          tempfile.puts(CSV.generate_line(fields, csv_options))
        end
        tempfile.open # Reopen the temporary file
        update_attributes!(report: tempfile)
      end
    end
  end

  serialize :plate_purpose_ids, Array

  before_validation :generate_name, on: %i[create build]

  after_create :schedule_report

  validates :report_type, presence: true

  validates :study_id, numericality: true, if: :report_type_selection?, allow_nil: true
  validates :start_date, presence: { if: :report_type_selection? }
  validates :end_date, presence: { if: :report_type_selection?, date: { after_or_equal_to: :start_date } }

  validates :barcodes_text, presence: { if: :report_type_barcodes? }
  validate :barcodes_are_recognised, if: :report_type_barcodes?
  validate :plates_are_found, if: :report_type_selection?

  def report_type_selection?
    report_type == 'selection'
  end

  def report_type_barcodes?
    report_type == 'barcodes'
  end

  def barcodes_are_recognised
    if barcodes_list.blank?
      errors.add(:barcodes_text, 'Please enter some barcodes in the text area')
      return
    end

    ean13_barcodes_list = []
    invalid_barcodes_list = []
    barcodes_list.each do |cur_bc|
      if barcode_is_human_readable?(cur_bc)
        # human readable format
        ean13_barcodes_list.push(Barcode.human_to_machine_barcode(cur_bc))
      elsif barcode_is_ean13?(cur_bc)
        # already ean 13 format so unchanged
        ean13_barcodes_list.push(cur_bc)
      else
        invalid_barcodes_list.push(cur_bc)
      end
    end

    unless invalid_barcodes_list.size.zero?
      errors.add(:barcodes_text, "Invalid barcodes found: #{invalid_barcodes_list.join(',')}")
      return
    end

    if ean13_barcodes_list.size.zero?
      errors.add(:barcodes_text, 'Please enter some valid barcodes (human or scannable) in the text area')
      return
    end

    self.barcodes = ean13_barcodes_list.join(' ')
  end

  def plates_are_found
    unless Plate.search_for_plates(
      study_id:             study_id,
      start_date:           start_date,
      end_date:             end_date,
      plate_purpose_ids:    plate_purpose_ids
    ).any?
      errors.add(:study_id, 'Those selection criteria return no plates')
    end
  end

  def schedule_report
    Delayed::Job.enqueue LocationReportJob.new(id)
  end

  def generate_report_rows
    plates_list = []

    if report_type == 'barcodes'
      ean13_barcodes_list = []
      self.barcodes_list = barcodes.strip.split(/[\s]+/)
      if barcodes_list.empty?
        yield(['Error: barcodes list was empty when generating the report'])
        return
      end
      barcodes_list.each do |cur_bc|
        if barcode_is_human_readable?(cur_bc)
          # human readable format
          ean13_barcodes_list.push(Barcode.human_to_machine_barcode(cur_bc))
        elsif barcode_is_ean13?(cur_bc)
          # ean 13 format so unchanged
          ean13_barcodes_list.push(cur_bc)
        end
      end

      # fetch the plates for the batch of barcodes
      plates_list = Plate.with_machine_barcode(ean13_barcodes_list)
    elsif report_type == 'selection'
      plates_list = search_for_plates_by_selection
    end

    if plates_list.empty?
      yield(['Error: plates list was empty when generating the report'])
      return
    end

    yield headers

    plates_list.each do |cur_plate|
      if cur_plate.studies.present?
        cur_plate.studies.each do |cur_study|
          yield([
            cur_plate.machine_barcode,
            cur_plate.sanger_human_barcode,
            cur_plate.plate_purpose.name,
            cur_plate.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            cur_plate.storage_location,
            cur_plate.storage_location_service,
            cur_study.name,
            cur_study.study_metadata.faculty_sponsor.name
          ])
        end
      else
        # no study found (unlikely)
        yield([
          cur_plate.machine_barcode,
          cur_plate.sanger_human_barcode,
          cur_plate.plate_purpose.name,
          cur_plate.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          cur_plate.storage_location,
          cur_plate.storage_location_service,
          'Unknown',
          'Unknown'
        ])
      end
    end
  end

  private

  def generate_name
    self.name ||= Time.current.to_formatted_s(:number)
  end

  def search_for_plates_by_selection
    Plate.search_for_plates(
      study_id:             study_id,
      start_date:           start_date,
      end_date:             end_date,
      plate_purpose_ids:    plate_purpose_ids
    )
  end

  def barcode_is_human_readable?(bc)
    bc.match?(/\A([A-z]{2})([0-9]{1,7})[A-z]{0,1}\z/)
  end

  def barcode_is_ean13?(bc)
    bc.match?(/^\d{13}$/)
  end
end
