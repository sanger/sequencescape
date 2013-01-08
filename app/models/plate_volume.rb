class PlateVolume < ActiveRecord::Base
  extend DbFile::Uploader

  has_uploaded :uploaded, { :serialization_column => "uploaded_file_name" }

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
      map  = Map.find_for_cell_location(well_description,plate.size) or raise "Cannot find location for #{well_description.inspect} on plate size #{plate.size}"
      well = location_to_well[map] or raise "Could not find well #{map.description} on plate #{plate.id} (barcode: #{plate.barcode})"
      well.well_attribute.update_attributes!(:measured_volume => volume.to_f)
    end
  end
  private :update_well_volumes

  def extract_well_volumes
    return if self.uploaded.nil?
    head, *tail = FasterCSV.parse(self.uploaded.file.read)
    tail.each { |(barcode, location, volume)| yield(location, volume) }
  end
  private :extract_well_volumes

  # Is an update required given the timestamp specified
  def update_required?(modified_timestamp = Time.now)
    self.updated_at < modified_timestamp
  end

  def call(filename, file)
    return unless update_required?(file.stat.mtime)
    db_files.map(&:destroy!)
    update_attributes!(:uploaded_file_name => filename, :updated_at => file.stat.mtime, :uploaded => file)
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
        find_for_filename(filename).call(filename, file)
      end
    rescue => exception
      Rails.logger.warn("Error processing volume file #{filename}: #{exception.message}")
    end
    private :handle_volume

    def find_for_filename(filename)
      self.find_by_uploaded_file_name(filename) or
      lambda { |filename, file| PlateVolume.create!(:uploaded_file_name => filename, :updated_at => file.stat.mtime, :uploaded => file) }
    end
  end
end
