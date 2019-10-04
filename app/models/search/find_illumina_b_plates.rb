require "#{Rails.root}/app/models/illumina_b/plate_purposes"

# Handled finding of plates for the defunct Illumina-B pipelines
# Can be deprecated.
# Api endpoints can be deprecated by raising {::Core::Service::DeprecatedAction}
class Search::FindIlluminaBPlates < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.

    Plate.include_plate_purpose
         .with_purpose(illumina_b_plate_purposes)
         .with_no_outgoing_transfers.in_state(criteria['state'])
  end

  def illumina_b_plate_purposes
    names = (IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS + IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS + Pulldown::PlatePurposes::ISCH_PURPOSE_FLOWS).flatten.uniq
    PlatePurpose.where(name: names)
  end
  private :illumina_b_plate_purposes
end
