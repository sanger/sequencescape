# frozen_string_literal: true
require 'carrierwave'

class PlateVolume < ApplicationRecord # rubocop:todo Style/Documentation
  ASSAY_TYPE = 'Volume Check'
  ASSAY_VERSION = '1.0'
  extend DbFile::Uploader

  has_uploaded :uploaded, serialization_column: 'uploaded_file_name'

  before_validation :calculate_barcode_from_filename
  after_save :update_well_volumes

  # Is an update required given the timestamp specified
  def update_required?(modified_timestamp)
    updated_at.to_i < modified_timestamp.to_i
  end

  def call(filename, file)
    return unless update_required?(file.stat.mtime)

    db_files.map(&:destroy)
    reload
    update!(uploaded_file_name: filename, updated_at: file.stat.mtime, uploaded: file)
  end

  private

  def calculate_barcode_from_filename
    return if uploaded_file_name.blank?

    match = uploaded_file_name.match(/^([\w-]+).csv/i)
    return if match.nil?

    self.barcode = match[1]
  end

  def update_well_volumes
    qc_assay = QcAssay.new
    extract_well_volumes do |well_description, volume|
      short_well_description = Map.strip_description(well_description)
      well = location_to_well[short_well_description]
      next if well.blank?

      QcResult.create(
        asset: well,
        key: 'volume',
        value: volume,
        units: 'ul',
        assay_type: ASSAY_TYPE,
        assay_version: ASSAY_VERSION,
        qc_assay: qc_assay
      )
    end
  end

  def plate
    @plate ||= Plate.find_by_barcode(barcode) or throw :no_source_plate
  end

  def location_to_well
    @location_to_well ||= plate.wells.includes(:map, :well_attribute).indexed_by_location
  end

  def extract_well_volumes
    return if uploaded.nil?

    head, *tail = CSV.parse(uploaded.file.read)
    tail.each { |(_barcode, location, volume)| yield(location, volume) }
  end

  class << self
    def process_all_volume_check_files(folder = configatron.plate_volume_files)
      all_plate_volume_file_names(folder).each do |filename|
        File.open(File.join(folder, filename), 'r') { |file| catch(:no_source_plate) { handle_volume(filename, file) } }
      end
    end

    def all_plate_volume_file_names(folder)
      Dir.entries(folder).reject { |f| File.directory?(File.join(folder, f)) }
    end
    private :all_plate_volume_file_names

    def handle_volume(filename, file)
      ActiveRecord::Base.transaction { find_for_filename(sanitized_filename(file)).call(filename, file) }
    rescue => e
      Rails.logger.warn("Error processing volume file #{filename}: #{e.message}")
    end
    private :handle_volume

    def sanitized_filename(file)
      # We need to use the Carrierwave sanitized filename for lookup, else files with spaces are repetedly processed
      # Later versions of carrierwave expose this sanitization better, but for now we are forced to create an object
      CarrierWave::SanitizedFile.new(file).filename
    end

    def find_for_filename(filename)
      find_by(uploaded_file_name: filename) or
        lambda do |filename, file|
          PlateVolume.create!(uploaded_file_name: filename, updated_at: file.stat.mtime, uploaded: file)
        end
    end
  end
end
