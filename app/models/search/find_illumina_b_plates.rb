class Search::FindIlluminaBPlates < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    PlateForInbox.with_plate_purpose(illumina_b_plate_purposes).with_no_outgoing_transfers.in_state(criteria['state']).located_in(freezer)
  end

  def illumina_b_plate_purposes
    names = IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten.concat(IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
    PlatePurpose.find_all_by_name(names)
  end
  private :illumina_b_plate_purposes

  def freezer
    Location.find_by_name('Library creation freezer') or raise ActiveRecord::RecordNotFound, 'Library creation freezer'
  end
  private :freezer
end
