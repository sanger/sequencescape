class IlluminaB::PcrPlatePurpose < PlatePurpose
  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, contents = nil)
    nudge_parent_plate(plate, state, contents)
    default_transition_to(plate, state, contents)
  end

  def nudge_parent_plate(plate, state, contents)
    case state
    when 'started_fx' then plate.parent.transition_to('started', contents)
    when 'started_mj' then plate.parent.transition_to('passed',  contents)
    end
  end
  private :nudge_parent_plate
end
