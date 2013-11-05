module FluidigmHelper

  def self.map_configuration_for(width,height,plate_layout)
    wells = []
    size = width*height
    digit_count = Math.log10(size+1).ceil
    height.times do |r|
      width.times do |c|
        wells << {
          :description  => "S%0#{digit_count}d" % [(width*r)+c+1],
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
