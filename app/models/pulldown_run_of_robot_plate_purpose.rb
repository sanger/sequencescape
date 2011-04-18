class PulldownRunOfRobotPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("EnRichment 1")]
  end
end
