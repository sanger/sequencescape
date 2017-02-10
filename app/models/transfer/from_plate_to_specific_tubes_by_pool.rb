# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class Transfer::FromPlateToSpecificTubesByPool < Transfer::BetweenPlateAndTubes
  attr_reader :targets
  def targets=(uuids_for_tubes)
    # {'pool_uuid'=>'target_uuid'}
    @targets = Uuid.lookup_many_uuids(uuids_for_tubes.values).map(&:resource)
    @pools_to_tubes = Hash.new
    uuids_for_tubes.each do |pool_uuid, target_uuid|
      @pools_to_tubes[Uuid.find_id(pool_uuid, 'Submission')] = Uuid.find_by(external_id: target_uuid).resource
    end
  end

  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?
    @pools_to_tubes[well.pool_id]
  end
  private :locate_mx_library_tube_for
end
