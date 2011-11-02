class PlateVolume < ActiveRecord::Base
  
  # New file storage:
  has_many :db_files, :as => :owner, :dependent => :destroy
  #  Mount Carrierwave on report field
  mount_uploader :uploaded, PolymorphicUploader, :mount_on => "uploaded_file_name"

  OFFSET = 1

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

    extract_well_volumes.each do |well_description, volume|
      map  = Map.find_for_cell_location(well_description,plate.size)
      well = location_to_well[map] or raise "Could not find well #{map.description} on plate #{plate.id} (barcode: #{plate.barcode})"
      well.well_attribute.update_attributes!(:measured_volume => volume.to_f)
    end
  end
  private :update_well_volumes

  def extract_well_volumes
    return if self.uploaded.blank?
    csv = FasterCSV.parse(self.uploaded.file.read)
    (OFFSET...csv.size).map { |row| [ csv[row][1], csv[row][2] ] }
  end
  private :extract_well_volumes

  # Is an update required given the timestamp specified
  def update_required?(modified_timestamp = Time.now)
    self.updated_at < modified_timestamp
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
        plate_volume, timestamp = self.find_by_uploaded_file_name(filename), file.stat.mtime
        attributes = { :uploaded => file, :uploaded_file_name => filename, :updated_at => timestamp }
        case
        when plate_volume.nil?                        then self.create!(attributes)
        when plate_volume.update_required?(timestamp) then plate_volume.update_attributes!(attributes)
        else Rails.logger.debug "Skipping #{filename} as #{timestamp.to_s} is before #{plate_volume.updated_at.to_s}"
        end
      end
    rescue => exception
      Rails.logger.warn("Error processing volume file #{filename}: #{exception.message}")
    end
    private :handle_volume
  end

end
