# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent::SampleManifestUpdated < BroadcastEvent
  set_event_type 'sample_manifest.updated'

  # Properties takes :updated_samples_ids

  seed_class SampleManifest

  has_subject(:study, :study)
  has_subjects(:labware, :labware)
  has_subjects(:sample) { |_, e| Sample.find(e.properties[:updated_samples_ids]) }

  has_metadata(:labware_type, :asset_type)
  has_metadata(:supplier, :supplier_name)
end
