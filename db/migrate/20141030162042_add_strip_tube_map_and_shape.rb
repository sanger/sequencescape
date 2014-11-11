class AddStripTubeMapAndShape < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Map::AssetShape.create!(
        :name => 'StripTubeColumn',
        :horizontal_ratio => 1,
        :vertical_ratio   => 8,
        :description_strategy => 'Map::Sequential'
      ).generate_map(8)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Map::AssetShape.find_by_name('StripTubeColumn').tap do |shape|
        Map.find_all_by_shape(shape).each(&:destroy)
        shape.destroy
      end
    end
  end
end
