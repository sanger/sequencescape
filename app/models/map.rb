class Map < ActiveRecord::Base
  named_scope :for_position_on_plate, lambda { |position,plate_size| 
    {
      :conditions => {
        :description => horizontal_plate_position_to_description(position, plate_size),
        :asset_size  => plate_size
      }
    } 
  }

  named_scope :where_description, lambda { |*descriptions| { :conditions => { :description => descriptions.flatten } } }
  named_scope :where_plate_size,  lambda { |size| { :conditions => { :asset_size => size } } }
	named_scope :where_vertical_plate_position, lambda { |*positions| { :conditions => { :column_order => positions.map {|v| v-1} } } }

  def vertical_plate_position
    self.column_order + 1
  end

  def horizontal_plate_position
    self.row_order + 1
  end

  def snp_id
    self.horizontal_plate_position
  end

  def self.location_from_row_and_column(row, column)
    "#{(?A+row).chr}#{column}"
  end

  def self.next_map_position(current_map_id)
    map = Map.find(current_map_id)
    map_position = Map.description_to_horizontal_plate_position(map.description,map.asset_size)
    return nil if map_position +1 >  map.asset_size
    horiz_description = Map.horizontal_plate_position_to_description(map_position +1,map.asset_size)
    Map.find_by_description_and_asset_size(horiz_description,map.asset_size)
  end

  def self.next_vertical_map_position(current_map_id)
    map = Map.find(current_map_id)
    Map.next_vertical_map_position_from_description(map.description,map.asset_size)
  end
  
  def self.next_vertical_map_position_from_description(description,asset_size)
    map_position = Map.description_to_vertical_plate_position(description,asset_size)
    return nil if map_position +1 >  asset_size
    horiz_description = Map.vertical_plate_position_to_description(map_position +1,asset_size)
    Map.find_by_description_and_asset_size(horiz_description,asset_size)
  end
  

  def self.map_96wells
    Map.all(:conditions => {:asset_size => 96})
  end

  def self.map_384wells
    Map.all(:conditions => {:asset_size => 384})
  end

  def self.snp_map_id_to_pipelines_map_id(snp_map_id,plate_size)
    description = Map.horizontal_plate_position_to_description(snp_map_id,plate_size)
    map_id = Map.first(:conditions => ["description like ? AND asset_size = ? ", description, plate_size ]).id
  end

  def self.pipelines_map_id_to_snp_map_id(pipelines_map_id)
    map = Map.find(pipelines_map_id)
    description = Map.description_to_horizontal_plate_position(map.description,map.asset_size)
  end

  def self.description_to_horizontal_plate_position(well_description,plate_size)
    return nil unless valid_well_description_and_plate_size?(well_description,plate_size)
    split_well = split_well_description(well_description)
    width = self.plate_width(plate_size)
    return nil if width.nil?
    (width*split_well[:row]) + split_well[:col]
  end

  def self.description_to_vertical_plate_position(well_description,plate_size)
    return nil unless valid_well_description_and_plate_size?(well_description,plate_size)
    split_well = split_well_description(well_description)
    length = self.plate_length(plate_size)
    return nil if length.nil?
    (length*(split_well[:col]-1)) + split_well[:row]+1
  end

  def self.horizontal_plate_position_to_description(well_position,plate_size)
    return nil unless valid_plate_position_and_plate_size?(well_position,plate_size)
    width = plate_width(plate_size)
    return nil if width.nil?
    horizontal_position_to_description(well_position, width)
  end

  def self.vertical_plate_position_to_description(well_position,plate_size)
    return nil unless valid_plate_position_and_plate_size?(well_position,plate_size)
    length = plate_length(plate_size)
    return nil if length.nil?
    vertical_position_to_description(well_position, length)
  end

  def self.horizontal_to_vertical(well_position,plate_size)
    desc = self.horizontal_plate_position_to_description(well_position,plate_size)
    self.description_to_vertical_plate_position(desc,plate_size)
  end

  def self.vertical_to_horizontal(well_position,plate_size)
    desc = self.vertical_plate_position_to_description(well_position,plate_size)
    self.description_to_horizontal_plate_position(desc,plate_size)
  end

  def self.plate_width(plate_size)
    return nil unless plate_size.is_a? Integer
    if plate_size == 96
      width  = 12
    elsif plate_size == 384
      width = 24
    else
      return nil
    end
    width
  end

  def self.plate_length(plate_size)
    return nil unless plate_size.is_a? Integer
    if plate_size == 96
      length  = 8
    elsif plate_size == 384
      length = 16
    else
      return nil
    end
    length
  end

  def self.valid_plate_size?(plate_size)
    plate_size.is_a?(Integer) && plate_size >0
  end

  def self.valid_well_position?(well_position)
    well_position.is_a?(Integer) && well_position >0
  end

  def self.valid_plate_position_and_plate_size?(well_position,plate_size)
    return false unless valid_well_position?(well_position)
    return false unless valid_plate_size?(plate_size)
    return false if well_position > plate_size
    true
  end

  def self.valid_well_description_and_plate_size?(well_description,plate_size)
    return false if well_description.blank?
    return false unless valid_plate_size?(plate_size)
    true
  end

  def self.vertical_position_to_description(well_position, length)
    desc_letter = (((well_position-1)%length) + 65).chr
    desc_number = ((well_position-1)/length) +1
    (desc_letter+(desc_number.to_s))
  end

  def self.horizontal_position_to_description(well_position, width)
    desc_letter = (((well_position-1)/width) + 65).chr
    desc_number = ((well_position-1)%width) +1
    (desc_letter+(desc_number.to_s))
  end

  def self.split_well_description(well_description)
    { :row=> well_description[0] - 65, :col=> well_description[1,well_description.size].to_i}
  end

  def self.find_for_cell_location(cell_location, asset_size)
    self.find_by_description_and_asset_size(cell_location.sub(/0(\d)$/, '\1'), asset_size)
  end
  
  def self.pad_description(map)
    split_description = split_well_description(map.description)
    return "#{map.description[0].chr}0#{split_description[:col]}" if split_description[:col] < 10
      
    map.description
  end

  named_scope :in_row_major_order, { :order => 'row_order ASC' }
  named_scope :in_reverse_row_major_order, { :order => 'row_order DESC' }
  named_scope :in_column_major_order, { :order => 'column_order ASC' }
  named_scope :in_reverse_column_major_order, { :order => 'column_order DESC' }

  class << self
    def plate_dimensions(plate_size)
      case plate_size
      when 96  then yield(12, 8)
      when 384 then yield(24, 16)
      else raise StandardError, "Cannot determine plate dimensions for #{plate_size}"
      end
    end

    # Walking in column major order goes by the columns: A1, B1, C1, ... A2, B2, ...
    def walk_plate_in_column_major_order(size, &block)
      self.all(:conditions => { :asset_size => size }, :order => 'column_order ASC').each do |position|
        yield(position, position.column_order)
      end
    end
    alias_method(:walk_plate_vertically, :walk_plate_in_column_major_order)

    # Walking in row major order goes by the rows: A1, A2, A3, ... B1, B2, B3 ....
    def walk_plate_in_row_major_order(size, &block)
      self.all(:conditions => { :asset_size => size }, :order => 'row_order ASC').each do |position|
        yield(position, position.row_order)
      end
    end
  end
end
