class PulldownEnrichmentThreePlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("EnRichment 4")]
  end
end
