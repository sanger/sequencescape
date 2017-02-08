# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class ControlPlate < Plate
  self.prefix = 'DN'

  AFFY_WELL_LOCATIONS = ['G1', 'H1']
  ILLUMINA_CONTROL_WELL_LOCATIONS = ['A1', 'C1', 'E1']

  def illumina_wells
    wells.includes(:map).where(maps: { description: ILLUMINA_CONTROL_WELL_LOCATIONS, asset_size: 96 })
  end

  def affy_wells
    wells.includes(:map).where(maps: { description: AFFY_WELL_LOCATIONS, asset_size: 96 })
  end
  deprecate(affy_wells: 'assumed this was not used, needs map_id fixes')
end
