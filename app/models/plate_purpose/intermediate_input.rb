class PlatePurpose::IntermediateInput < PlatePurpose
  READY_STATE = 'passed'
  def state_of(plate)
    return READY_STATE if plate.ancestors.count == 0
    super(plate)
  end
end