module PlatePurpose::WorksOnLibraryRequests
  def self.included(base)
    base.class_eval do
      include Transfer::WellHelpers
    end
  end

  def each_well_and_its_library_request(plate, &block)
    locate_stock_wells_for(plate).each do |well, stock_wells|
      library_request = stock_wells.first.requests_as_source.where_is_a?(Pulldown::Requests::LibraryCreation).first or next
      yield(well, library_request)
    end
  end
  private :each_well_and_its_library_request
end
