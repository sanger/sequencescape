class Search::FindIlluminaBTubes < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Tube.include_purpose.with_purpose(illumina_b_tube_purposes).with_no_outgoing_transfers.in_state(criteria['state']).without_finished_tubes(illumina_b_final_tube_purpose)
  end

  def self.illumina_b_tube_purposes
    @tube_purposes ||= Tube::Purpose.find_all_by_name(
      IlluminaB::PlatePurposes::TUBE_PURPOSE_FLOWS.flatten
    )
  end
  delegate :illumina_b_tube_purposes, :to => 'self.class'

  def self.illumina_b_final_tube_purpose
    @last_tube ||= Tube::Purpose.find_all_by_name(
      IlluminaB::PlatePurposes::TUBE_PURPOSE_FLOWS.map(&:last)
    )
  end
  delegate :illumina_b_final_tube_purpose, :to => 'self.class'

end
