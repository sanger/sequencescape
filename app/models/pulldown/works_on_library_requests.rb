module Pulldown::WorksOnLibraryRequests
  def self.included(base)
    base.class_eval do
      include Transfer::WellHelpers
    end
  end

  def each_well_and_its_library_request(plate, &block)
    plate.wells.each do |well|
      stock_well      = locate_stock_well_for(well) or next
      library_request = stock_well.requests_as_source.where_is_a?(PulldownLibraryCreationRequest).first or next
      yield(well, library_request)
    end
  end
  private :each_well_and_its_library_request
end
