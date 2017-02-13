# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

require 'carrierwave'

class PlateVolume < ActiveRecord::Base
  extend DbFile::Uploader

  has_uploaded :uploaded, serialization_column: 'uploaded_file_name'

  before_save :calculate_barcode_from_filename
  after_save :update_well_volumes

  def calculate_barcode_from_filename
    return if uploaded_file_name.blank?
    match = uploaded_file_name.match(/^(\d+).csv/i)
    return if match.nil?
    self.barcode = match[1]
  end
  private :calculate_barcode_from_filename

  def update_well_volumes
    plate = Plate.include_wells_and_attributes.find_from_machine_barcode(barcode) or throw :no_source_plate
    location_to_well = plate.wells.map_from_locations

    extract_well_volumes do |well_description, volume|
      map  = Map.find_for_cell_location(well_description, plate.size) or raise "Cannot find location for #{well_description.inspect} on plate size #{plate.size}"
      well = location_to_well[map]
      well.well_attribute.update_attributes!(measured_volume: volume.to_f) if well.present?
    end
  end
  private :update_well_volumes

  def extract_well_volumes
    return if uploaded.nil?
    head, *tail = CSV.parse(uploaded.file.read)
    tail.each { |(_barcode, location, volume)| yield(location, volume) }
  end
  private :extract_well_volumes

  # Is an update required given the timestamp specified
  def update_required?(modified_timestamp = Time.now)
    updated_at < modified_timestamp
  end

  def call(filename, file)
    return unless update_required?(file.stat.mtime)
    db_files.map(&:destroy)
    reload
    update_attributes!(uploaded_file_name: filename, updated_at: file.stat.mtime, uploaded: file)
  end

  class << self
    def process_all_volume_check_files
      all_plate_volume_file_names.each do |filename|
        File.open(File.join(configatron.plate_volume_files, filename), 'r') do |file|
          catch(:no_source_plate) { handle_volume(filename, file) }
        end
      end
    end

    def all_plate_volume_file_names
      Dir.entries(configatron.plate_volume_files).reject { |f| File.directory?(File.join(configatron.plate_volume_files, f)) }
    end
    private :all_plate_volume_file_names

    def handle_volume(filename, file)
      ActiveRecord::Base.transaction do
        find_for_filename(sanitized_filename(file)).call(filename, file)
      end
    rescue => exception
      Rails.logger.warn("Error processing volume file #{filename}: #{exception.message}")
    end
    private :handle_volume

    def sanitized_filename(file)
      # We need to use the Carrierwave sanitized filename for lookup, else files with spaces are repetedly processed
      # Later versions of carrierwave expose this sanitization better, but for now we are forced to create an object
      CarrierWave::SanitizedFile.new(file).filename
    end

    def find_for_filename(filename)
      find_by(uploaded_file_name: filename) or
      ->(filename, file) { PlateVolume.create!(uploaded_file_name: filename, updated_at: file.stat.mtime, uploaded: file) }
    end
  end
end
