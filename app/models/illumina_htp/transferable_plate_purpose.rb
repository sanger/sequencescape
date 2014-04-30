class IlluminaHtp::TransferablePlatePurpose < IlluminaHtp::FinalPlatePurpose
  include PlatePurpose::Library

  def source_plate(plate)
    plate.parent.stock_plate
  end

  def transition_to(plate, state, contents = nil)
    super
    connect_requests(plate, state, contents)
  end

  def connect_requests(plate, state, contents = nil)
    return unless state == 'qc_complete'
    wells = plate.wells
    wells = wells.located_at(contents) unless contents.blank?

    wells.each do |target_well|
      source_wells = target_well.stock_wells
      source_wells.each do |source_well|
        upstream = source_well.requests.detect {|r| r.is_a?(IlluminaHtp::Requests::SharedLibraryPrep) }
        downstream = upstream.submission.next_requests(upstream)
        upstream.update_attributes!(:target_asset=> target_well)
        downstream.each { |ds| ds.update_attributes!(:asset => target_well) }
        upstream.pass!
      end
    end
  end

  def each_well_and_its_library_request(plate, &block)
    well_to_stock_id = Hash[plate.wells.map { |well| [well.id, well.stock_wells.first.try(:id)] }.reject { |_,v| v.nil? }]
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
