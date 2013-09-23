class AddFluidgmMaps < ActiveRecord::Migration

  require 'lib/fluidgm_helper'

  def self.up
    ActiveRecord::Base.transaction do
      Map.create!(configurations)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      configurations.each do |config|
        Map.find(:first, :conditions=>config).destroy
      end
    end
  end

  def self.configurations
    FluidgmHelper.map_configuration_for(6,16,Map::AssetShape.find_by_name('Fluidgm96').id) + FluidgmHelper.map_configuration_for(12,16,Map::AssetShape.find_by_name('Fluidgm192').id)
  end
end
