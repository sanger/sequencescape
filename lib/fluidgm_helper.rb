module FluidgmHelper

  def self.map_configuration_for(width,height,plate_layout)
    wells = []
    size = width*height
    height.times do |r|
      width.times do |c|
        wells << {
          :description  => "S#{(width*r)+c+1}",
          :location_id  => ((width*r)+c+1),
          :asset_size   => size,
          :row_order    => ((width*r)+c),
          :column_order => ((height*c)+r),
          :asset_shape_id  => plate_layout
        }
      end
    end
    wells
  end

end
