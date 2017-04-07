class AddPlateTypes < ActiveRecord::Migration
  def up
    plate_types_with_maximum_volume.each do |name, maximum_volume|
      PlateType.create!(name: name, maximum_volume: maximum_volume)
    end
  end

  def down
    plate_types_with_maximum_volume.each do |name, _maximum_volume|
      plate_type = PlateType.find_by(name: name)
      plate_type.destroy if plate_type.present?
    end
  end

  def plate_types_with_maximum_volume
    { 'ABgene_0765' => 800, 'ABgene_0800' => 180, 'FluidX075' => 500, 'FluidX03' => 280 }
  end
end
