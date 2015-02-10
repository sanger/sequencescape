#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class PulldownPlate < Plate
  def self.initialize_child_plates
    #FIXME: refactor to make PulldownPlate.count work
    PulldownAliquotPlate
    PulldownSonicationPlate
    PulldownRunOfRobotPlate
    PulldownEnrichmentOnePlate
    PulldownEnrichmentTwoPlate
    PulldownEnrichmentThreePlate
    PulldownEnrichmentFourPlate
    PulldownSequenceCapturePlate
    PulldownPcrPlate
    PulldownQpcrPlate
  end

end
