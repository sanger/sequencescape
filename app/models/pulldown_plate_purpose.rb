class PulldownPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Pulldown Aliquot")]
  end
end
