class AddPlateShapes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Map::AssetShape.create!(
        :name => 'Standard',
        :horizontal_ratio => 3,
        :vertical_ratio   => 2,
        :description_strategy => Map::Coordinate
      )
      Map::AssetShape.create!(
        :name => 'Fluidgm96',
        :horizontal_ratio => 3,
        :vertical_ratio   => 8,
        :description_strategy => Map::Sequential
      )
      Map::AssetShape.create!(
        :name => 'Fluidgm192',
        :horizontal_ratio => 3,
        :vertical_ratio   => 4,
        :description_strategy => Map::Sequential
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Map::AssetShape.find_all_by_name(['Standard','Fluidgm96','Fluidgm192'])
    end
  end
end
