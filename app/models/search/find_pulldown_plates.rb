class Search::FindPulldownPlates < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Plate.include_wells_with_aliquots.include_plate_purpose.with_plate_purpose(pulldown_plate_purposes).with_no_outgoing_transfers
  end

  def self.pulldown_plate_purposes
    @plate_purposes ||= PlatePurpose.find_all_by_name(
      Pipeline::Pulldown::PULLDOWN_PLATE_PURPOSE_FLOWS.flatten
    )
  end
  delegate :pulldown_plate_purposes, :to => 'self.class'
end
