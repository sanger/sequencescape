class IlluminaHtp::PostShearQcPlatePurpose < PlatePurpose
  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, contents = nil, customer_accepts_responsibility = false)
    nudge_parent_plate(plate, state, contents)
    default_transition_to(plate, state, contents,customer_accepts_responsibility)
  end

  def nudge_parent_plate(plate, state, contents)
    case state
    when 'started' then plate.parent.transition_to('started', contents)
    when 'passed' then plate.parent.transition_to('passed',  contents)
    end
  end
  private :nudge_parent_plate
end
