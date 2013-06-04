class IlluminaC::StockPurpose < PlatePurpose
  include PlatePurpose::Stock

  def transition_to(plate, state, contents = nil)
    return unless ['failed','cancelled'].include?(state)
    plate.wells.located_at(contents).each do |well|
      well.requests.each {|r| r.cancel_before_started! if r.is_a?(IlluminaC::Requests::LibraryRequest) }
    end
  end
end
