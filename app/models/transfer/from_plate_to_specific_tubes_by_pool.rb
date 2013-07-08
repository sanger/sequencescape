class Transfer::FromPlateToSpecificTubesByPool < Transfer::BetweenPlateAndTubes
  attr_reader :targets
  def targets=(uuids_for_tubes)
    # {'pool_uuid'=>'target_uuid'}
    @targets = Uuid.lookup_many_uuids(uuids_for_tubes.values).map(&:resource)
    @pools_to_tubes = Hash.new
    uuids_for_tubes.each do |pool_uuid,target_uuid|
      @pools_to_tubes[Uuid.find_id(pool_uuid, 'Submission')] = Uuid.find_by_external_id(target_uuid).resource
    end
  end

  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?
    @pools_to_tubes[well.pool_id]
  end
  private :locate_mx_library_tube_for
end
