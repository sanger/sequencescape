# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

require_dependency 'illumina_htp/plate_purposes'

class Search::FindIlluminaAPlates < Search
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    Plate.include_plate_purpose.with_plate_purpose(illumina_a_plate_purposes).with_no_outgoing_transfers.in_state(criteria['state']).located_in(freezer)
  end

  def illumina_a_plate_purposes
    PlatePurpose.where(name: IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
  end
  private :illumina_a_plate_purposes

  def freezer
    Location.find_by(name: 'Illumina high throughput freezer') or raise ActiveRecord::RecordNotFound, 'Illumina high throughput freezer'
  end
  private :freezer
end
