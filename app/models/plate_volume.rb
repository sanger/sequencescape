class PlateVolume < ActiveRecord::Base
  has_attached_file :uploaded, :storage => :database
  default_scope select_without_file_columns_for(:uploaded)

  attr_accessor :uploaded_content_type
  attr_accessor :uploaded_file_size
  attr_accessor :uploaded_updated_at

  OFFSET = 1

  before_save :calculate_barcode_from_filename
  after_save :update_well_volumes

  def update_well_volumes
    plate = Plate.find_from_machine_barcode(barcode)
    raise "Couldnt find source plate" if plate.nil?

    extract_well_volumes.each do |well_description, volume|
      map = Map.find_for_cell_location(well_description,plate.size)
      well = plate.find_well_by_name(map.description)
      raise "Couldnt find well #{map.description} on plate #{plate.barcode}" if well.nil?
      well.well_attribute.update_attributes!(:measured_volume => volume.to_f)
    end
  end

  def extract_well_volumes
    return if self.uploaded.blank?
    csv = FasterCSV.parse(self.uploaded_file)
    well_volumes = []
    OFFSET.upto(csv.size-1) do |row|
      well_volumes << [ csv[row][1], csv[row][2] ]
    end

    well_volumes
  end

  def self.all_plate_volume_file_names
    Dir.entries(configatron.plate_volume_files)
  end

  def self.process_all_volume_check_files
    self.all_plate_volume_file_names.each do |filename|
      begin
        file = File.open(configatron.plate_volume_files+"#{filename}")
        plate_volume = PlateVolume.find_by_uploaded_file_name(filename)
        if plate_volume
          plate_volume.update_attributes!(:uploaded => file)
        else
          self.create!(:uploaded => file, :uploaded_file_name => filename)
        end
      rescue
      end
      file.close
    end
  end

  def calculate_barcode_from_filename
    return if uploaded_file_name.blank?
    match = uploaded_file_name.match(/^([\d]+).(csv|CSV)/)
    return if match.nil?
    self.barcode = match[1]
  end

end
