# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

##
# This form object class handles the user interaction for creating new Location Reports.
# It sensibility checks the user-entered list of barcode sequences or selection parameters
# before creating the Location Report model.
class LocationReport::FormObject
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  # Attributes
  attr_accessor :user,
                :name,
                :report_type,
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
  validate :has_a_name?
  validates :report_type, presence: true
  validates :study_id, presence: true, allow_nil: true
  validate :are_both_dates_present_if_used?
  validate :is_end_date_after_start_date?
  validate :are_entered_barcodes_valid?
  validate :any_select_field_present?
  validate :are_any_plates_found?

  def save
    p 'in save'
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

  def has_a_name?
    self.name = name.gsub(/[^A-Za-z0-9_\-\.\s]/, '').squish.gsub(/\s/, '_') if name.present?
    self.name = Time.current.to_formatted_s(:number) if name.blank?
    errors.add(:report_name, 'TODO: no name found') unless name.present?
  end

  def are_both_dates_present_if_used?
    p 'in are_both_dates_present_if_used?'
    if ((start_date.blank? && end_date.present?) || (start_date.present? && end_date.blank?)) then
      errors.add(:base, 'TODO: both dates must be entered')
    end
  end

  def parse_barcodes
    barcodes_text&.squish&.split(/[\s\,]+/) || []
  end

  def are_entered_barcodes_valid?
    p 'in are_entered_barcodes_valid?'
    return true unless barcodes_text.present?
    invalid_barcodes = []
    valid_barcodes = {}
    parse_barcodes.each do |cur_bc|
      if barcode_is_human_readable?(cur_bc)
        cur_bc = Barcode.human_to_machine_barcode(cur_bc).to_s
        check_bc_unique?(valid_barcodes, cur_bc)
      elsif barcode_is_ean13?(cur_bc)
        check_bc_unique?(valid_barcodes, cur_bc)
      else
        invalid_barcodes << cur_bc
      end
    end
    p "valid barcodes = #{valid_barcodes.inspect}"
    self.barcodes = valid_barcodes.keys if valid_barcodes.present?
    p "barcodes = #{barcodes}"
    errors.add(:base, I18n.t('location_reports.errors.invalid_barcodes_found') + invalid_barcodes.join(',')) unless invalid_barcodes.blank?
    errors.add(:base, I18n.t('location_reports.errors.no_valid_barcodes_found')) if barcodes.blank?
  end

  def check_bc_unique?(valid_barcodes, cur_bc)
    p 'in check_bc_unique'
    if valid_barcodes.key?(cur_bc)
      errors.add(:base, I18n.t('location_reports.errors.duplicate_barcode_found') + cur_bc)
      false
    else
      valid_barcodes[cur_bc] = 1
      true
    end
  end

  def barcode_is_human_readable?(bc)
    bc.match?(/\A([A-z]{2})([0-9]{1,7})[A-z]{0,1}\z/)
  end

  def barcode_is_ean13?(bc)
    bc.match?(/^\d{13}$/)
  end

  def any_select_field_present?
    p 'in any_select_field_present'
    return unless report_type == 'type_selection'
    p "type_selection"
    attr_list = %i(faculty_sponsor_ids study_id start_date end_date plate_purpose_ids barcodes_text)
    errors.add(:base, "TODO: fill summat in!") if attr_list.all?{ |attr| send(attr).blank? }
  end

  def are_any_plates_found?
    p 'in are_any_plates_found?'
    return unless report_type == 'type_selection'
    p 'checking plates exist'
    errors.add(:base, I18n.t('location_reports.errors.no_rows_found')) unless search_for_plates_by_selection.any?
  end

  def is_end_date_after_start_date?
    p 'in is_end_date_after_start_date?'
    return if (start_date.blank? || end_date.blank?)

    if end_date < start_date
      errors.add(:end_date, "TODO: End cannot be before the start date") 
    end 
  end

  def search_for_plates_by_selection
    p 'in search_for_plates_by_selection'
    params = {
      faculty_sponsor_ids:  faculty_sponsor_ids,
      study_id:             study_id,
      start_date:           start_date&.to_datetime,
      end_date:             end_date&.to_datetime,
      plate_purpose_ids:    plate_purpose_ids,
      barcodes:             barcodes
    }
    p "params = #{params.inspect}"
    Plate.search_for_plates(params)
  end

  def persist!
    p 'in persist'
    LocationReport.transaction do
      @location_report = LocationReport.new(name: name)
      @location_report.
      return if @location_report.save

      errors.add(:base, I18n.t('location_reports.errors.failed_to_save_location_report'))
      @location_report.errors.full_messages.each do |msg|
        errors.add_to_base("LocationReport Error: #{msg}")
      end
    end
  end
end
