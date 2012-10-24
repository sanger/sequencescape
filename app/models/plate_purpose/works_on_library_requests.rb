module PlatePurpose::WorksOnLibraryRequests
  def self.included(base)
    base.class_eval do
      include Transfer::WellHelpers
    end
  end

  def each_well_and_its_library_request(plate, &block)
    well_to_stock_id = Hash[plate.stock_wells.map { |well,stock_wells| [well.id, stock_wells.first.id] }]
    requests         = Request::LibraryCreation.for_asset_id(well_to_stock_id.values).include_request_metadata.group_by(&:asset_id)
    plate.wells.all(:include => { :aliquots => :library }).each do |well|
      next if well.aliquots.empty?
      stock_id       = well_to_stock_id[well.id] or raise "No stock well for #{well.id.inspect} (#{well_to_stock_id.inspect})"
      stock_requests = requests[stock_id]        or raise "No requests for stock well #{stock_id.inspect} (#{requests.inspect})"
      yield(well, stock_requests.first)
    end
  end
  private :each_well_and_its_library_request
end
