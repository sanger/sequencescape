class PlatePurpose::IntermediateInput < PlatePurpose
  READY_STATE = 'passed'
  def state_of(plate)
    return READY_STATE if valid_intermediate_input?(plate)
    super(plate)
  end

  def valid_intermediate_input?(plate)
    [
      (plate.ancestors.count == 0),
      has_library_creation?(plate)
    ].all?
  end

  def has_library_creation?(plate)
    return false if plate.wells.with_contents.empty?
    plate.wells.with_contents.all? do |w| 
      return false if w.requests.empty?
      w.requests.all? do |r| 
        r.kind_of?(Request::LibraryCreation) || r.kind_of?(LibraryCreationRequest)
      end
    end
  end
end