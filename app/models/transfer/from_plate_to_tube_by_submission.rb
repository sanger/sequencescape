# At the end of the pulldown pipeline the wells of the final plate are transferred, individually,
# into MX library tubes.  Each well is effectively a pool of the stock wells, once they've been
# through the pipeline, so the mapping needs to be based on the original submissions.
class Transfer::FromPlateToTubeBySubmission < Transfer
  include ControlledDestinations

  # TODO: This should be a has_many association
  attr_accessor :destinations

  #--
  # The source plate wells need to be translated back to the stock plate wells, which simply
  # involves following the transfer requests back up until we hit the stock plate.  We only need
  # to follow one transfer request for each well as the submission related stock wells will be in
  # the same final well.  Once we get to the stock well we then find the request that has the 
  # well as a source and the target is an MX library tube.
  #++
  def well_to_destination
    ActiveSupport::OrderedHash[
      source.wells.map do |well|
        tube = locate_mx_library_tube_for(locate_stock_well_for(well))
        tube.nil? ? nil : [ well, tube ]
      end.compact
    ]
  end
  private :well_to_destination

  def locate_mx_library_tube_for(stock_well)
    return nil if stock_well.nil?
    stock_well.requests_as_source.detect { |request| request.target_asset.is_a?(MultiplexedLibraryTube) }.try(:target_asset)
  end
  private :locate_mx_library_tube_for

  def record_transfer(source, destination)
    self.transfers    ||= []
    self.destinations ||= []

    self.transfers    << source.map.description
    self.destinations << destination
  end
  private :record_transfer
end
