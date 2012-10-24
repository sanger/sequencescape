# Creates all of the Map instances in the DB for all know plate sizes.  This assumes a horizontal orientation
# of the plate, i.e.:
#
#   1 2 3 4 5 6 7 8 9
# A . . . . . . . . .
# B . . . . . . . . .
# C . . . . . . . . .
# D . . . . . . . . .
#
map_data = []
[ 96, 384 ].each do |plate_size|
  Map.plate_dimensions(plate_size) do |width, height|
    details = (0...plate_size).map do |index|
      {
        :location_id => index + 1,
        :description => Map.horizontal_plate_position_to_description(index+1, plate_size),
        :asset_size  => plate_size
      }
    end

    (0...plate_size).each do |index|
      details[((index % height)*width)+(index/height)][:column_order] = index
      details[index][:row_order] = index
    end

    map_data.concat(details)
  end
end

COLUMNS = [:location_id, :description, :asset_size, :column_order, :row_order]

map_data.each do |details|
  Map.create(details)
end