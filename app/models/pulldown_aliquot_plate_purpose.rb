class PulldownAliquotPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Sonication")]
  end
end
