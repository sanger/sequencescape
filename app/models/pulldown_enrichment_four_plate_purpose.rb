class PulldownEnrichmentFourPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("Sequence Capture")]
  end
end
