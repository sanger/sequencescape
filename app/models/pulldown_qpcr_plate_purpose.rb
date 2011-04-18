class PulldownQpcrPlatePurpose < PlatePurpose
  def child_plate_purposes
    # FIXME
    [PlatePurpose.find_by_name("Pulldown qPCR")]
  end
end
