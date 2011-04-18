class PulldownSonicationPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Run of Robot")]
  end
end
