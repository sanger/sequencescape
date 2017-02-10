# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.

require "#{Rails.root}/app/models/illumina_b/plate_purposes"
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
class Search::FindIlluminaBPlates < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Plate.include_plate_purpose.with_plate_purpose(illumina_b_plate_purposes).with_no_outgoing_transfers.in_state(criteria['state']).located_in(freezer)
  end

  def illumina_b_plate_purposes
    names = (IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS + IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS + Pulldown::PlatePurposes::ISCH_PURPOSE_FLOWS).flatten.uniq
    PlatePurpose.where(name: names)
  end
  private :illumina_b_plate_purposes

  def freezer
    Location.find_by(name: 'Illumina high throughput freezer') or raise ActiveRecord::RecordNotFound, 'Illumina high throughput freezer'
  end
  private :freezer
end
