module Search::FindIlluminaPlates
  
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Plate.include_plate_metadata.include_plate_purpose.with_plate_purpose(illumina_b_plate_purposes).with_no_outgoing_transfers.in_state(criteria['state']).located_in(freezer)
  end

  def freezer
    Location.find_by_name('Illumina high throughput freezer') or raise ActiveRecord::RecordNotFound, @freezer_name
  end
  private :freezer

  def illumina_b_plate_purposes
    names = IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten.concat(IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
    PlatePurpose.find_all_by_name(names)
  end
  private :illumina_b_plate_purposes

  def illumina_a_plate_purposes
    PlatePurpose.find_all_by_name(IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
  end
  private :illumina_a_plate_purposes
end