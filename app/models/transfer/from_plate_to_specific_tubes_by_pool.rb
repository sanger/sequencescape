# frozen_string_literal: true
class Transfer::FromPlateToSpecificTubesByPool < Transfer::BetweenPlateAndTubes
  # Not used since 2017-07-24 10:32:21
  attr_reader :targets

  def targets=(uuids_for_tubes)
    # {'pool_uuid'=>'target_uuid'}
    @targets = Uuid.include_resource.lookup_many_uuids(uuids_for_tubes.values).map(&:resource)
    uuid_targets = @targets.index_by(&:uuid)
    @pools_to_tubes = {}
    uuids_for_tubes.each do |pool_uuid, target_uuid|
      @pools_to_tubes[Uuid.find_id(pool_uuid, 'Submission')] = uuid_targets[target_uuid]
    end
  end

  private

  def apply_name?(tube)
    tube.name.blank?
  end

  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?

    @pools_to_tubes[well.pool_id]
  end
end
