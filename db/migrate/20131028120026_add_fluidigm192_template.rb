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
