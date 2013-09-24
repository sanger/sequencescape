class Map < ActiveRecord::Base

  class AssetShape < ActiveRecord::Base
    set_table_name('asset_shapes')

    def self.default_id
      @default ||= Map::AssetShape.find_by_name('Standard').id
    end

    def standard?
      horizontal_ratio == 3 && vertical_ratio == 2
    end

    def multiplier(size)
      ((size/(vertical_ratio*horizontal_ratio))**0.5).to_i
    end
    private :multiplier

    def plate_height(size)
      multiplier(size)*vertical_ratio
    end

    def plate_width(size)
      multiplier(size)*horizontal_ratio
    end
  end

  module Coordinate

    # TODO: These methods are only valid for standard plates. Moved them here to make that more explicit
    # (even if its not strictly appropriate) They could do with refactoring/removing.

    PLATE_DIMENSIONS = Hash.new { |h,k| [] }.merge(
      96  => [ 12, 8 ],
      384 => [ 24, 16 ]
    )

    def self.description_to_horizontal_plate_position(well_description,plate_size)
      return nil unless valid_well_description_and_plate_size?(well_description,plate_size)
      split_well = Map.split_well_description(well_description)
      width = self.plate_width(plate_size)
      return nil if width.nil?
      (width*split_well[:row]) + split_well[:col]
    end

    def self.description_to_vertical_plate_position(well_description,plate_size)
      return nil unless valid_well_description_and_plate_size?(well_description,plate_size)
      split_well = Map.split_well_description(well_description)
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

    def self.descriptions_for_row(row,size)
      (1..plate_width(size)).map {|column| "#{row}#{column}"}
    end

    def self.descriptions_for_column(column,size)
      (0...plate_length(size)).map {|row| Map.location_from_row_and_column(row,column)}
    end

    def self.plate_width(plate_size)
      PLATE_DIMENSIONS[plate_size].first
    end

    def self.plate_length(plate_size)
      PLATE_DIMENSIONS[plate_size].last
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

    def self.horizontal_to_vertical(well_position,plate_size)
      alternate_position(well_position, plate_size, :width, :length)
    end

    def self.vertical_to_horizontal(well_position,plate_size)
      alternate_position(well_position, plate_size, :length, :width)
    end

  class << self
    # Given the well position described in terms of a direction (vertical or horizontal) this function
    # will map it to the alternate positional representation, i.e. a vertical position will be mapped
    # to a horizontal one.  It does this with the divisor and multiplier, which will be reversed for
    # the alternate.
    #
    # NOTE: I don't like this, it just makes things clearer than it was!
    # NOTE: I hate the nil returns but external code would take too long to change this time round
    def alternate_position(well_position, size, *dimensions)
      return nil unless valid_well_position?(well_position)
      divisor, multiplier = dimensions.map { |n| send("plate_#{n}", size) }
      return nil if divisor.nil? or multiplier.nil?
      column, row = (well_position-1).divmod(divisor)
      return nil unless (0...multiplier).include?(column)
      return nil unless (0...divisor).include?(row)
      alternate = (row * multiplier) + column + 1
    end
    private :alternate_position
  end

  end

  module Sequential

  end

  named_scope :for_position_on_plate, lambda { |position,plate_size,asset_shape|
    {
      :conditions => {
        :row_order    => position - 1,
        :asset_size     => plate_size,
        :asset_shape_id => asset_shape.id
      }
    }
  }

  named_scope :where_description, lambda { |*descriptions| { :conditions => { :description => descriptions.flatten } } }
  named_scope :where_plate_size,  lambda { |size| { :conditions => { :asset_size => size } } }
  named_scope :where_plate_shape,  lambda { |asset_shape| { :conditions => { :asset_shape_id => asset_shape.id } } }
  named_scope :where_vertical_plate_position, lambda { |*positions| { :conditions => { :column_order => positions.map {|v| v-1} } } }

  belongs_to :asset_shape, :class_name => 'Map::AssetShape'
  delegate :standard?, :to => :asset_shape

  def vertical_plate_position
    self.column_order + 1
  end

  def horizontal_plate_position
    self.row_order + 1
  end

  def snp_id
    raise StandardError, "Only standard maps can be converted to SNP" unless map.standard?
    self.horizontal_plate_position
  end

  def self.location_from_row_and_column(row, column)
    "#{(?A+row).chr}#{column}"
  end

  def self.next_map_position(current_map_id)
    Map.find(current_map_id).next_map_position
  end

  def next_map_position
    Map.find(:first,:conditions=>{
      :asset_size=> asset_size,
      :asset_shape_id=> asset_shape_id,
      :row_order => row_order+1
      })
  end

  def self.horizontal_to_vertical(well_position,plate_size)
    Map::Coordinate.horizontal_to_vertical(well_position,plate_size)
  end

  def self.vertical_to_horizontal(well_position,plate_size)
    Map::Coordinate.vertical_to_horizontal(well_position,plate_size)
  end

  def self.next_vertical_map_position(current_map_id)
    Map.find(current_map_id).next_vertical_map_position
  end

  def next_vertical_map_position
    Map.find(:first,:conditions=>{
      :asset_size=> asset_size,
      :asset_shape_id=> asset_shape_id,
      :column_order => column_order+1
      })
  end

  def self.map_96wells
    Map.all(:conditions => {:asset_size => 96})
  end

  def self.map_384wells
    Map.all(:conditions => {:asset_size => 384})
  end

  def self.snp_map_id_to_pipelines_map_id(snp_map_id,plate_size)
    # We're only going to be getting standard plates in through SNP
    Map.find(:first,:conditions=>{
      :asset_size  => plate_size,
      :row_order   => snp_map_id.to_i+1,
      :asset_shape => Map::AssetShape.default_id
    }).id
  end

  def self.pipelines_map_id_to_snp_map_id(pipelines_map_id)
    # We're only going to be getting standard plates in through SNP
    Map.find(pipelines_map_id).snp_id
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
    def walk_plate_in_column_major_order(size, asset_shape=nil, &block)
      asset_shape ||= Map::AssetShape.default_id
      self.all(:conditions => { :asset_size => size, :asset_shape_id => asset_shape }, :order => 'column_order ASC').each do |position|
        yield(position, position.column_order)
      end
    end
    alias_method(:walk_plate_vertically, :walk_plate_in_column_major_order)

    # Walking in row major order goes by the rows: A1, A2, A3, ... B1, B2, B3 ....
    def walk_plate_in_row_major_order(size, asset_shape=nil, &block)
      asset_shape ||= Map::AssetShape.default_id
      self.all(:conditions => { :asset_size => size, :asset_shape_id => asset_shape }, :order => 'row_order ASC').each do |position|
        yield(position, position.row_order)
      end
    end
  end
end
