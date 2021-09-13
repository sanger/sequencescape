# frozen_string_literal: true
class TagLayout::WalkWellsByPools < TagLayout::Walker # rubocop:todo Style/Documentation
  self.walking_by = 'wells in pools'

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def walk_wells # rubocop:todo Metrics/CyclomaticComplexity
    # Adjust each of the groups so that any wells that are in the same pool as those at the same position
    # in the group to the left are moved to a non-clashing position.  Effectively this makes the view of the
    # plate slightly jagged.
    group_size =
      direction.to_sym == :column ? Map::Coordinate.plate_length(plate.size) : Map::Coordinate.plate_width(plate.size)
    wells_in_groups =
      wells_in_walking_order
        .with_pool_id
        .in_groups_of(group_size)
        .map { |wells| wells.map { |well| [well, well.pool_id] } }
    wells_in_groups.each_with_index do |current_group, group|
      next if group == 0

      prior_group = wells_in_groups[group - 1]

      current_group.each_with_index do |well_and_pool, index|
        break if prior_group.size <= index

        # Assume that, if the current well isn't in a pool, that it is in the same pool as the well prior
        # to it in the group.  That way empty wells are treated as though they are part of the pool.
        well_and_pool[-1] ||= (index.zero? ? prior_group.last : current_group[index - 1]).last
        next unless prior_group[index].last == well_and_pool.last

        current_group.push(well_and_pool) # Move the well to the end of the group

        # rubocop:todo Layout/LineLength
        current_group[index] = [nil, well_and_pool.last] # Blank out the well at the current position but maintain the pool
        # rubocop:enable Layout/LineLength
      end
    end

    # Now we can walk the wells in the groups, skipping any that have been nil'd by the above code.
    wells_in_groups.each { |group| group.each_with_index { |(well, _), index| yield(well, index) unless well.nil? } }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
end
