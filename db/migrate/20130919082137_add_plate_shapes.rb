#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddPlateShapes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      AssetShape.create!(
        :name => 'Standard',
        :horizontal_ratio => 3,
        :vertical_ratio   => 2,
        :description_strategy => 'Map::Coordinate'
      )
      AssetShape.create!(
        :name => 'Fluidigm96',
        :horizontal_ratio => 3,
        :vertical_ratio   => 8,
        :description_strategy => 'Map::Sequential'
      )
      AssetShape.create!(
        :name => 'Fluidigm192',
        :horizontal_ratio => 3,
        :vertical_ratio   => 4,
        :description_strategy => 'Map::Sequential'
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      AssetShape.find_all_by_name(['Standard','Fluidigm96','Fluidigm192'])
    end
  end
end
