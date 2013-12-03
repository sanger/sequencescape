class IlluminaHtp::FinalPlatePurpose < PlatePurpose
  include PlatePurpose::Library

  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, contents = nil,customer_accepts_responsibility=false)
    nudge_pre_pcr_wells(plate, state, contents,customer_accepts_responsibility)
    default_transition_to(plate, state, contents,customer_accepts_responsibility)
  end

  def attatched?(plate)
    plate.state == ('qc_complete')
  end

  def fail_stock_well_requests(wells,_)
    # Handled by the nudge of the pre PCR wells!
  end
  private :fail_stock_well_requests

  def nudge_pre_pcr_wells(plate, state, contents,customer_accepts_responsibility)
    plate.parent.parent.transition_to(state, contents,customer_accepts_responsibility) if state == 'failed'
  end
  private :nudge_pre_pcr_wells
end
