module Pulldown::WorksOnLibraryRequests
  def each_well_and_its_library_request(plate, &block)
    plate.wells.each do |well|
      transfer_request = well.transfer_requests_as_target.first or next
      library_request  = transfer_request.asset.requests_as_source.where_is_a?(PulldownLibraryCreationRequest).first
      yield(well, library_request)
    end
  end
  private :each_well_and_its_library_request
end
