class IlluminaC::LibPcrPurpose < PlatePurpose
  include PlatePurpose::Library

  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, contents = nil)
    nudge_parent_plate(plate, state, contents)
    default_transition_to(plate, state, contents)
  end

  def nudge_parent_plate(plate, state, contents)
    plate.parent.transition_to(state, contents) if ['started','passed'].include?(state)
  end
  private :nudge_parent_plate
end
