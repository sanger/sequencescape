# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

class LocationReport < ApplicationRecord
  # includes / extends
  extend DbFile::Uploader

  # attributes / variables
  attr_accessor :barcodes_list
  serialize :faculty_sponsor_ids, Array
  serialize :plate_purpose_ids, Array
  serialize :barcodes, Array
  self.per_page = 20
  enum report_type: %i[type_selection type_labwhere]

  # relations
  belongs_to :study
  belongs_to :user

  # scopes
  scope :for_user, ->(user) { where(user_id: user.id) }

  # actions
  # before_validation :generate_name, on: %i[create build]
  # before_validation :check_entered_barcodes, on: %i[create build], if: :barcodes_text?
  after_create :schedule_report
  has_uploaded :report, serialization_column: 'report_filename'

  # validations
  validates :report_type, presence: true
  # validates :barcodes, presence: { if: :type_barcodes? }
  validates_presence_of :barcodes, allow_nil: true
  # validate :barcodes_are_recognised, on: %i[create build], if: :barcodes_text?
  # validates :study, presence: true, allow_nil: true
  # validates_presence_of :start_date, if: :end_date?
  # validates_presence_of :end_date, if: :start_date?
  # validates_presence_of :end_date, date: { after_or_equal_to: :start_date}
  # validate :end_date_is_after_start_date
  # validate :any_select_field_present?, on: %i[create build], if: :type_selection?
  # validate :plates_are_found, on: %i[create], if: :type_selection?

  # def barcodes_text
  #   barcodes_list.join(' ') unless @barcodes_list.nil?
  # end

  # # converts the barcodes entered by the user into a list
  # def barcodes_text=(value)
  #   self.barcodes_list = if value.nil?
  #                          []
  #                        else
  #                          value.strip.split(/[\s]+/)
  #                        end
  # end

  def column_headers
    %w[ScannedBarcode HumanBarcode Type Created Location Service StudyName StudyId FacultySponsor]
  end

  def generate!
    csv_options = { row_sep: "\r\n", force_quotes: true }
    filename    = ['locn_rpt', name].join('_') + '.csv'

    ActiveRecord::Base.transaction do
      Tempfile.open(filename) do |tempfile|
        generate_report_rows do |fields|
          tempfile << CSV.generate_line(fields, csv_options)
        end
        tempfile.rewind
        update_attributes!(report: tempfile)
      end
    end
  end

  # def check_entered_barcodes
  #   @invalid_barcodes_list = []
  #   barcodes_list.each do |cur_bc|
  #     if barcode_is_human_readable?(cur_bc)
  #       barcodes << Barcode.human_to_machine_barcode(cur_bc).to_s
  #     elsif barcode_is_ean13?(cur_bc)
  #       barcodes << cur_bc
  #     else
  #       @invalid_barcodes_list << cur_bc
  #     end
  #   end
  # end

  # def barcodes_are_recognised
  #   errors.add(:base, I18n.t('location_reports.errors.invalid_barcodes_found') + @invalid_barcodes_list.join(',')) unless @invalid_barcodes_list.size.zero?
  # end

  # def any_select_field_present?
  #   if %w(faculty_sponsor_ids study start_date end_date plate_purpose_ids).all?{|attr| self[attr].blank?}
  #     errors.add :base, "Select summat!"
  #   end
  # end

  # def plates_are_found
  #   errors.add(:base, I18n.t('location_reports.errors.no_rows_found')) unless search_for_plates_by_selection.any?
  # end

  def schedule_report
    Delayed::Job.enqueue LocationReportJob.new(id)
  end

  def generate_report_rows
    generate_plates_list

    if @plates_list.empty?
      yield([I18n.t('location_reports.errors.plate_list_empty')])
      return
    end

    yield column_headers

    @plates_list.each do |cur_plate|
      if cur_plate.studies.present?
        cur_plate.studies.each do |cur_study|
          yield(generate_report_row(cur_plate, cur_study))
        end
      else
        yield(generate_report_row(cur_plate, nil))
      end
    end
  end

  #######
  private
  #######

  # def end_date_is_after_start_date
  #   return if end_date.blank? || start_date.blank?

  #   if end_date < start_date
  #     errors.add(:end_date, "TODO: Cannot be before the start date") 
  #   end 
  # end

  def generate_plates_list
    @plates_list = if type_barcodes?
                     Plate.with_machine_barcode(barcodes)
                   elsif type_selection?
                     search_for_plates_by_selection
                   else
                     []
                   end
  end

  def generate_report_row(cur_plate, cur_study)
    row = generate_plate_cols_for_row(cur_plate)
    row + generate_study_cols_for_row(cur_study)
  end

  def generate_plate_cols_for_row(cur_plate)
    cols = [] << cur_plate.machine_barcode
    cols << cur_plate.sanger_human_barcode
    # NB. some older plates do not have a purpose
    cols << (cur_plate.plate_purpose&.name || 'Unknown')
    cols << cur_plate.created_at.strftime('%Y-%m-%d %H:%M:%S')
    cols << cur_plate.storage_location
    cols << cur_plate.storage_location_service
  end

  def generate_study_cols_for_row(cur_study)
    return %w[Unknown Unknown] if cur_study.blank?

    # NB. some older studies may not have a name
    cols = [] << (cur_study.name || cur_study.id)
    cols << cur_study.id
    # NB. some studies may not have a faculty sponsor
    cols << (cur_study.study_metadata.faculty_sponsor&.name || 'Unknown')
  end

  # def generate_name
  #   self.name = name.gsub(/[^A-Za-z0-9_\-\.\s]/, '').squish.gsub(/\s/, '_') if name.present?
  #   self.name = Time.current.to_formatted_s(:number) if name.blank?
  # end

  def search_for_plates_by_selection
    params = {
      faculty_sponsor_ids:  faculty_sponsor_ids,
      study_id:             study_id,
      start_date:           start_date,
      end_date:             end_date,
      plate_purpose_ids:    plate_purpose_ids,
      barcodes:             barcodes
    }
    Plate.search_for_plates(params)
  end

  # def barcode_is_human_readable?(bc)
  #   bc.match?(/\A([A-z]{2})([0-9]{1,7})[A-z]{0,1}\z/)
  # end

  # def barcode_is_ean13?(bc)
  #   bc.match?(/^\d{13}$/)
  # end
end
