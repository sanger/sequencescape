# frozen_string_literal: true
class TagLayout::WalkManualWellsByPools < TagLayout::Walker
  self.walking_by = 'wells in pools'

  def walk_wells
    # This is much simple than the automated method
    wells_in_pools = wells_in_walking_order.with_pool_id.group_by(&:pool_id)

    # Now we can walk the wells in the groups, skipping any that have been nil'd by the above code.
    wells_in_pools.each do |_pool, wells|
      wells.each_with_index { |(well, _), index| yield(well, index) unless well.nil? }
    end
  end
end
