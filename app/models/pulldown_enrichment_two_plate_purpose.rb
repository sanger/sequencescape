class PulldownEnrichmentTwoPlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("EnRichment 3")]
  end
end
