#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddFluidigm192Template < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      well_array = Map.find_all_by_description(['S192,S180']).map do |map_loc|
        {:map => map_loc}
      end
      PlateTemplate.create!(:name=>'Fluidigm 192.24 Template') do |plate|
        plate.wells.create!(well_array)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlateTemplate.find_by_name('Fluidigm 192.24 Template').destroy
    end
  end
end
