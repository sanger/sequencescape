# frozen_string_literal: true

plate_types_with_maximum_volume = {
  'ABgene_0765' => 800,
  'ABgene_0800' => 180,
  'FluidX075' => 500,
  'FluidX03' => 280,
  'KingFisher 96 2ml' => 2000
}

plate_types_with_maximum_volume.each do |name, maximum_volume|
  PlateType.create!(name: name, maximum_volume: maximum_volume)
end
