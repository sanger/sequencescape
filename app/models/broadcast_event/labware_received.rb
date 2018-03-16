# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2017 Genome Research Ltd.

class BroadcastEvent::LabwareReceived < BroadcastEvent
  set_event_type 'labware.received'

  seed_class Asset

  seed_subject :labware
  has_subjects(:study, :studies)
  has_subject(:labware, :labware)
  has_subjects(:sample, :contained_samples)

  has_metadata(:location_barcode) { |_asset, event| event.properties[:location_barcode] }
end
