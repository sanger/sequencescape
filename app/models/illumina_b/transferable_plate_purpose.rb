class IlluminaB::TransferablePlatePurpose < IlluminaB::FinalPlatePurpose
  include PlatePurpose::Library

  def transition_to(plate, state, contents = nil)
    super
    connect_requests(plate, state, contents)
  end

  def connect_requests(plate, state, contents = nil)
    return unless state == 'qc_complete'
    plate.wells.located_at(contents).each do |target_well|
      source_wells = target_well.stock_wells
      source_wells.each do |source_well|
        upstream = source_well.requests.detect {|r| r.is_a?(IlluminaB::Requests::SharedLibraryPrep) }
        downstream = upstream.submission.next_requests(upstream)
        upstream.update_attributes!(:target_asset=> target_well)
        downstream.each { |ds| ds.update_attributes!(:asset => target_well) }
        upstream.pass!
      end
    end
  end

end
