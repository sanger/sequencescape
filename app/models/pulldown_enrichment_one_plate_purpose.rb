class PulldownEnrichmentOnePlatePurpose < PlatePurpose
  def child_plate_purposes
    [PlatePurpose.find_by_name("EnRichment 2")]
  end
end
