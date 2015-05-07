#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.

require "#{Rails.root.to_s}/app/models/illumina_b/plate_purposes"

class Search::FindIlluminaBPlatesForUser < Search::FindIlluminaBPlates
  def scope(criteria)
    # We find all plates that do not have transfers where they are the source.  Once a plate has been transferred (or marked
    # for transfer) the destination plate becomes the end of the chain.
    super.for_user(Uuid.lookup_single_uuid(criteria['user_uuid']).resource)
  end
end
