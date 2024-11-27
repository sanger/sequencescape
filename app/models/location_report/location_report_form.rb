# frozen_string_literal: true

##
# This form object class handles the user interaction for creating new Location Reports.
# It sensibility checks the user-entered list of barcode sequences or selection parameters
# before creating the Location Report model.
class LocationReport::LocationReportForm
  # includes / extends
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  # Attributes
  attr_accessor :user, :report_type, :faculty_sponsor_ids, :study_id, :start_date, :end_date, :plate_purpose_ids

  attr_accessor :barcodes_text
  attr_reader :name, :location_barcode
  attr_writer :location_report, :barcodes

  # validations
  validate :check_labwhere_location_exists,
           :check_maxlength_of_barcodes,
           :check_for_valid_barcodes,
           :check_location_report

  def name=(input_name)
    @name = input_name.gsub(/[^A-Za-z0-9_\-.\s]/, '').squish.gsub(/\s/, '_') if input_name.present?
    @name = Time.current.to_fs(:number) if input_name.blank?
  end

  def location_barcode=(location_barcode)
    @location_barcode = location_barcode&.strip
  end

  def location_report
    @location_report ||
      @location_report =
        LocationReport.new(
          user: user,
          name: name,
          report_type: report_type,
          location_barcode: location_barcode,
          faculty_sponsor_ids: faculty_sponsor_ids,
          study_id: study_id,
          start_date: start_date&.to_datetime,
          end_date: end_date&.to_datetime,
          plate_purpose_ids: plate_purpose_ids,
          barcodes: barcodes
        )
  end

  def save
    location_report.save if valid?
  end

  # form builder methods (e.g. form_to) need the Active Model name to be set
  def self.model_name
    ActiveModel::Name.new(LocationReport)
  end

  def barcodes
    @barcodes ||= barcodes_text&.squish&.split(/[\s,]+/) || []
  end

  #######

  private

  #######

  def check_labwhere_location_exists
    return unless report_type == 'type_labwhere'
    return if find_labwhere_location.present?

    errors.add(:base, I18n.t('location_reports.errors.labwhere_location_not_found'))
  end

  def check_maxlength_of_barcodes
    return unless report_type == 'type_selection'
    return if barcodes_text.blank? || barcodes_text.length <= 60_000

    errors.add(:barcodes_text, I18n.t('location_reports.errors.barcodes_maxlength_exceeded'))
  end

  def check_for_valid_barcodes
    return unless report_type == 'type_selection'
    return if barcodes_text.blank? || barcodes.present?

    errors.add(:barcodes_text, I18n.t('location_reports.errors.no_valid_barcodes_found'))
  end

  def check_location_report
    return if location_report.valid?

    add_location_errors
  end

  def barcode_unique(valid_barcodes, cur_bc)
    if valid_barcodes.key?(cur_bc)
      errors.add(:base, I18n.t('location_reports.errors.duplicate_barcode_found') + cur_bc)
    else
      valid_barcodes[cur_bc] = 1
    end
  end

  def add_location_errors
    return if location_report.nil?

    # In Rails 6.1 object.errors returns ActiveModel::Errors, in Rails 6.0 it returns a Hash
    location_report.errors.each { |error| errors.add error.attribute, error.message }
  end

  def barcode_is_human_readable?(barcode)
    barcode.match?(SBCF::HUMAN_BARCODE_FORMAT)
  end

  def barcode_is_ean13?(barcode)
    barcode.match?(SBCF::MACHINE_BARCODE_FORMAT)
  end

  def find_labwhere_location
    locn_info = LabWhereClient::Location.find_by_barcode(location_barcode)
    return locn_info.name if locn_info.present?

    nil
  rescue LabWhereClient::LabwhereException
    nil
  end
end
