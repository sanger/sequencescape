# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module Pulldown::Requests
  # Whole genome sequencing library prep.
  # Entire genome is fragmented and prepared for sequencing.
  class WgsLibraryRequest < LibraryCreation
    fragment_size_details(300, 500)
  end
end
