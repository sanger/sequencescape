class PulldownMultiplexedLibraryCreationRequest < Request
  def valid_request_for_pulldown_report?
    well = self.asset
    return false if self.study.nil?
    return false if well.nil? || ! well.is_a?(Well)
    return false if well.plate.nil? || well.map.nil?
    return false if well.primary_aliquot.nil?
    return false if well.parent.nil? || ! well.parent.is_a?(Well)

    true
  end
end
