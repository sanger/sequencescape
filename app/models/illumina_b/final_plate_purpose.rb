class IlluminaB::FinalPlatePurpose < PlatePurpose
  include PlatePurpose::Library

  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, contents = nil)
    nudge_pre_pcr_wells(plate, state, contents)
    default_transition_to(plate, state, contents)
  end

  def fail_stock_well_requests(wells)
    # Handled by the nudge of the pre PCR wells!
  end
  private :fail_stock_well_requests

  def nudge_pre_pcr_wells(plate, state, contents)
    plate.parent.parent.transition_to(state, contents) if state == 'failed'
  end
  private :nudge_pre_pcr_wells
end
