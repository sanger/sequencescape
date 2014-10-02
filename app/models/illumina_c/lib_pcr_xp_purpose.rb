class IlluminaC::LibPcrXpPurpose < PlatePurpose

  def transition_to(plate, state, contents = nil, customer_accepts_responsibility=false)
    super
    connect_requests(plate, state, contents)
  end


  def connect_requests(plate, state, contents = nil)
    return unless state == 'qc_complete'
    wells = plate.wells
    wells = wells.located_at(contents).include_stock_wells unless contents.blank?

    wells.each do |target_well|
      source_wells = target_well.stock_wells
      source_wells.each do |source_well|
        source_well.requests.detect {|r| r.is_a?(IlluminaC::Requests::LibraryRequest) }.tap do |upstream|
          next unless upstream.target_asset.nil?
          upstream.update_attributes!(:target_asset=> target_well)
          upstream.pass!
        end
      end
    end
  end

end
