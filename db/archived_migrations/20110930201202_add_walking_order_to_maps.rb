#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddWalkingOrderToMaps < ActiveRecord::Migration
  class Map < ActiveRecord::Base
    self.table_name =('maps')

    def self.plate_dimensions(plate_size, &block)
      case plate_size
      when 96 then yield(12, 8)
      when 384 then yield(24, 16)
      else raise StandardError, "Cannot identify dimensions for #{plate_size}"
      end
    end
  end

  def self.up
    # Add the columns & ensure that they must be unique
    add_column :maps, :row_order, :integer, :unique => true
    add_column :maps, :column_order, :integer, :unique => true

    # Now, for each map instance fill in the column/row walking order
    Map.all(:order => 'location_id ASC').group_by(&:asset_size).each do |size, maps|
      Map.plate_dimensions(size) do |width, height|
        (0...size).each do |index|
          maps[((index % height)*width)+(index/height)].column_order = index
          maps[index].row_order = index
        end
      end

      maps.map(&:save!)
    end
  end

  def self.down
    remove_column :maps, :row_order
    remove_column :maps, :column_order
  end
end
