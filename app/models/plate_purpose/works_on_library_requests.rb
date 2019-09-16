module PlatePurpose::WorksOnLibraryRequests
  def each_well_and_its_library_request(plate)
    well_to_stock_id = Hash[plate.stock_wells.map { |well, stock_wells| [well.id, stock_wells.first.id] }]
    requests         = Request::LibraryCreation.for_asset_id(well_to_stock_id.values).include_request_metadata.group_by(&:asset_id)

    plate.wells.includes({ aliquots: :library }, :requests_as_target).find_each do |well|
      next if well.aliquots.empty?

      stock_id       = well_to_stock_id[well.id] or raise "No stock well for #{well.id.inspect} (#{well_to_stock_id.inspect})"
      stock_requests = requests[stock_id]        or raise "No requests for stock well #{stock_id.inspect} (#{requests.inspect})"
      stock_request  = stock_requests.detect { |stock_request| stock_request.submission_id == well.submission_ids.first }
      stock_request or raise "No requests for stock well #{stock_id.inspect} with matching submission (#{requests.inspect})"
      yield(well, stock_request)
    end
  end
  private :each_well_and_its_library_request
end
