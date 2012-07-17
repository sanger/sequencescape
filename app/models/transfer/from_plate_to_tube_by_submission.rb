# At the end of the pulldown pipeline the wells of the final plate are transferred, individually,
# into MX library tubes.  Each well is effectively a pool of the stock wells, once they've been
# through the pipeline, so the mapping needs to be based on the original submissions.
class Transfer::FromPlateToTubeBySubmission < Transfer::BetweenPlateAndTubes
  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?
    stock_wells.first.requests_as_source.detect { |request| request.target_asset.is_a?(Tube) }.try(:target_asset)
  end
  private :locate_mx_library_tube_for
end
