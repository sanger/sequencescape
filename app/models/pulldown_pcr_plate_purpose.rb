class PulldownPcrPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Pulldown qPCR")]
  end
end
