
class IlluminaB::FinalPlatePurpose < PlatePurpose
  include PlatePurpose::Library

  def transition_to(plate, state, contents = nil)
    plate.parent.parent.transition_to(state, contents) if state == 'passed'
    super
  end
end
