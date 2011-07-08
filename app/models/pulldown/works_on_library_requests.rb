module Pulldown::WorksOnLibraryRequests
  def self.included(base)
    base.class_eval do
      include Transfer::WellHelpers
    end
  end

  def each_well_and_its_library_request(plate, &block)
    plate.wells.each do |well|
      stock_well       = locate_stock_well_for(well) or next
      transfer_request = stock_well.transfer_requests_as_target.first or next
      library_request  = transfer_request.asset.requests_as_source.where_is_a?(PulldownLibraryCreationRequest).first
      yield(well, library_request)
    end
  end
  private :each_well_and_its_library_request
end
