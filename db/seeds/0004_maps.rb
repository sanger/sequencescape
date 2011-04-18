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
  (1..plate_size).map do |index|
    map_data << [
         index, 
         Map.horizontal_plate_position_to_description(index, plate_size), 
         plate_size]
  end
end

Map.import [:location_id, :description, :asset_size], map_data, :validate => false

