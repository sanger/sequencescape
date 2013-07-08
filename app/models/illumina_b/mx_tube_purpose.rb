class IlluminaB::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).first.asset.plate
  end
end
