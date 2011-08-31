# Lays out the tags so that they are based on the pool.
class TagLayout::ByPools < TagLayout
  # The direction of the tagging is column major, within the pools.
  class_inheritable_reader :direction
  write_inheritable_attribute(:direction, 'column')

  def walk_wells(&block)
    # Take the pools for this plate and flatten them out.  This ensures that the wells within a pool are
    # sequentially stored, and that the pools themselves are sequentially held.  Then we can replace each
    # of the well locations with the actual well that should be part of the pool.
    well_locations = plate.pools.values.flatten
    plate.wells.walk_in_column_major_order do |well, _|
      index                 = well_locations.index(well.map.description) or next
      well_locations[index] = well
    end

    # Finally the application of the tag is simply made by walking the flatten pools.
    well_locations.each_with_index(&block)
  end
  private :walk_wells
end
