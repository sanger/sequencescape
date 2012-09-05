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
