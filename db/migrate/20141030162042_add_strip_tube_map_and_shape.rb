#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
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
