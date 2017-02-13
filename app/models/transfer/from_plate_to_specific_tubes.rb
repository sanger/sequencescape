# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class Transfer::FromPlateToSpecificTubes < Transfer::BetweenPlateAndTubes
  attr_reader :targets
  def targets=(uuids_for_tubes)
    @targets = Uuid.lookup_many_uuids(uuids_for_tubes).map(&:resource)
  end

  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?
    @tubes_to_pick  ||= targets.dup
    @pools_to_tubes ||= Hash.new { |h, k| h[k] = @tubes_to_pick.shift or raise 'Not enough tubes to pick for pool' }
    @pools_to_tubes[well.pool_id]
  end
  private :locate_mx_library_tube_for
end
