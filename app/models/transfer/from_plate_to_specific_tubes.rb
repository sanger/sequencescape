class Transfer::FromPlateToSpecificTubes < Transfer::BetweenPlateAndTubes
  attr_reader :targets
  def targets=(uuids_for_tubes)
    @targets = Uuid.lookup_many_uuids(uuids_for_tubes).map(&:resource)
  end

  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?
    @tubes_to_pick  ||= targets.dup
    @pools_to_tubes ||= Hash.new { |h,k| h[k] = @tubes_to_pick.shift or raise "Not enough tubes to pick for pool" }
    @pools_to_tubes[well.pool_id]
  end
  private :locate_mx_library_tube_for
end
