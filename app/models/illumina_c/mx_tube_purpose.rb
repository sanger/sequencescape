class IlluminaC::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def stock_plate(tube)
    lt = library_request(tube)
    return lt.asset.plate if lt.present?

    nil
  end

  def library_request(tube)
    tube.requests_as_target.where_is_a(IlluminaC::Requests::LibraryRequest).first ||
      tube.requests_as_target.where_is_a(Request::Multiplexing).first.asset
          .requests_as_target.where_is_a(IlluminaC::Requests::LibraryRequest).first
  end

  private

  def mappings
    { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }
  end
end
