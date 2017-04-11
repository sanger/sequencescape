# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class PulldownMultiplexedLibraryCreationRequest < CustomerRequest
  # override default behavior to not copy the aliquots
  def on_started
  end

  def valid_request_for_pulldown_report?
    well = asset
    return false if well.nil? || !well.is_a?(Well)
    return false if well.plate.nil? || well.map.nil?
    return false if well.primary_aliquot.nil?
    return false if well.primary_aliquot.study.nil?
    return false if well.parent.nil? || !well.parent.is_a?(Well)

    true
  end
end
