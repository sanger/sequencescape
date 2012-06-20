
class IlluminaB::PcrPlatePurpose < PlatePurpose

  def transition_to(plate, state, contents = nil)
    plate.parent.transition_to(state, contents) if state == 'started'
    super
  end
end