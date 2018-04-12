# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

##
# This form object class handles the user interaction for creating new Location Reports.
# It sense checks the user-entered list of barcode sequences or other selection parameters
# before creating the Location Report model.
class LocationReport::FormObject
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  # Attributes
  attr_accessor :user,
                :name,
                :report_type,
                :location_barcode,
                :faculty_sponsor_ids,
                :study_id,
                :start_date,
                :end_date,
                :plate_purpose_ids,
                :barcodes_text,
                :barcodes

  # Access the location report and barcodes after it's saved
  attr_reader :location_report

  # Validations
  validate :name_present?
  validates :report_type, presence: true
  validate :location_barcode_present?
  validate :both_dates_present_if_used?
  validate :end_date_after_start_date?
  validate :entered_barcodes_valid?
  validate :any_select_field_present?
  validate :plates_found_by_selection?
  validate :labwhere_location_exists?

  def save
    if valid?
      persist!
      true
    else
      errors.add(:base, I18n.t('location_reports.errors.location_report_form_invalid'))
      false
    end
  end

  # form builder methods (e.g. form_to) need the Active Model name to be set
  def self.model_name
    ActiveModel::Name.new(LocationReport)
  end

  #######

  private

  #######

  def name_present?
    self.name = name.gsub(/[^A-Za-z0-9_\-\.\s]/, '').squish.gsub(/\s/, '_') if name.present?
    self.name = Time.current.to_formatted_s(:number) if name.blank?
    errors.add(:report_name, I18n.t('location_reports.errors.no_report_name_found')) if name.blank?
  end

  def location_barcode_present?
    return unless report_type == 'type_labwhere'
    errors.add(:location_barcode, I18n.t('location_reports.errors.no_location_barcode_found')) if location_barcode.blank?
  end

  def both_dates_present_if_used?
    errors.add(:start_date, I18n.t('location_reports.errors.both_dates_required')) if (start_date.blank? && end_date.present?) || (start_date.present? && end_date.blank?)
  end

  def parse_barcodes
    barcodes_text&.squish&.split(/[\s\,]+/) || []
  end

  def entered_barcodes_valid?
    return if barcodes_text.blank?
    invalid_barcodes = []
    valid_barcodes = {}
    parse_barcodes.each do |cur_bc|
      if barcode_is_human_readable?(cur_bc)
        begin
          cur_bc = Barcode.human_to_machine_barcode(cur_bc).to_s
          check_bc_unique?(valid_barcodes, cur_bc)
        rescue SBCF::InvalidBarcode
          invalid_barcodes << cur_bc
        end
      elsif barcode_is_ean13?(cur_bc)
        check_bc_unique?(valid_barcodes, cur_bc)
      else
        invalid_barcodes << cur_bc
      end
    end
    self.barcodes = valid_barcodes.keys if valid_barcodes.present?
    errors.add(:barcodes_text, I18n.t('location_reports.errors.invalid_barcodes_found') + invalid_barcodes.join(',')) if invalid_barcodes.present?
    errors.add(:barcodes_text, I18n.t('location_reports.errors.no_valid_barcodes_found')) if barcodes.blank?
  end

  def check_bc_unique?(valid_barcodes, cur_bc)
    if valid_barcodes.key?(cur_bc)
      errors.add(:base, I18n.t('location_reports.errors.duplicate_barcode_found') + cur_bc)
      false
    else
      valid_barcodes[cur_bc] = 1
      true
    end
  end

  def barcode_is_human_readable?(barcode)
    barcode.match?(/\A([A-z]{2})([0-9]{1,7})[A-z]{0,1}\z/)
  end

  def barcode_is_ean13?(barcode)
    barcode.match?(/^\d{13}$/)
  end

  def any_select_field_present?
    return unless report_type == 'type_selection'
    attr_list = %i[faculty_sponsor_ids study_id start_date end_date plate_purpose_ids barcodes_text]
    errors.add(:base, I18n.t('location_reports.errors.no_selection_fields_filled')) if attr_list.all? { |attr| send(attr).blank? }
  end

  def plates_found_by_selection?
    return unless report_type == 'type_selection'
    errors.add(:base, I18n.t('location_reports.errors.no_rows_found')) unless search_for_plates_by_selection.any?
  end

  def labwhere_location_exists?
    return unless report_type == 'type_labwhere'
    errors.add(:base, I18n.t('location_reports.errors.labwhere_location_not_found')) if find_labwhere_location.blank?
  end

  def end_date_after_start_date?
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, I18n.t('location_reports.errors.end_date_after_start_date')) if end_date < start_date
  end

  def search_for_plates_by_selection
    params = {
      faculty_sponsor_ids:  faculty_sponsor_ids,
      study_id:             study_id,
      start_date:           start_date&.to_datetime,
      end_date:             end_date&.to_datetime,
      plate_purpose_ids:    plate_purpose_ids,
      barcodes:             barcodes
    }
    Plate.search_for_plates(params)
  end

  def find_labwhere_location
    locn_info = LabWhereClient::Location.find_by_barcode(location_barcode) # rubocop:disable Rails/DynamicFindBy
    return locn_info.name if locn_info.present?
    nil
  rescue LabWhereClient::LabwhereException
    nil
  end

  def persist!
    LocationReport.transaction do
      @location_report                     = LocationReport.new(user: user, name: name, report_type: report_type)
      @location_report.location_barcode    = location_barcode if location_barcode.present?
      @location_report.faculty_sponsor_ids = faculty_sponsor_ids if faculty_sponsor_ids.present?
      @location_report.study_id            = study_id if study_id.present?
      @location_report.start_date          = start_date&.to_datetime if start_date.present?
      @location_report.end_date            = end_date&.to_datetime if end_date.present?
      @location_report.plate_purpose_ids   = plate_purpose_ids if plate_purpose_ids.present?
      @location_report.barcodes            = barcodes if barcodes.present?
      return if @location_report.save

      errors.add(:base, I18n.t('location_reports.errors.failed_to_save_location_report'))
      @location_report.errors.full_messages.each do |msg|
        errors.add_to_base("LocationReport Error: #{msg}")
      end
    end
  end
end
