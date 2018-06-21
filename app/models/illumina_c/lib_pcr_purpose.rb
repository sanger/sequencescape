
class IlluminaC::LibPcrPurpose < PlatePurpose
  include PlatePurpose::Library

  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    nudge_parent_plate(plate, state, user, contents)
    default_transition_to(plate, state, user, contents, customer_accepts_responsibility)
  end

  def nudge_parent_plate(plate, state, user, contents)
    plate.parent.transition_to(state, user, contents) if ['started', 'passed'].include?(state)
  end
  private :nudge_parent_plate
end
