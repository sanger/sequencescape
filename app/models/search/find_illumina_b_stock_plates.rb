class Search::FindIlluminaBStockPlates < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Plate.include_plate_metadata.include_plate_purpose.with_plate_purpose(illumina_b_stock_plate_purposes).with_no_outgoing_transfers.in_state(criteria['state'])
  end

  def self.illumina_b_stock_plate_purposes
    @plate_purposes ||= PlatePurpose.find_all_by_name(
      IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE
    )
  end
  delegate :illumina_b_stock_plate_purposes, :to => 'self.class'
end
