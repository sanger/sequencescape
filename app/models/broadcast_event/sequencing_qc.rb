#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent::SequencingQc < BroadcastEvent

  # Perform some magic to generate these dynamically using def self.event_type
  set_event_type 'sequencing_qc_pass'
  set_event_type 'sequencing_qc_fail'

  # Broadcast when npg sends us the qc event:
  # Study
  # Samples
  # Project
  # Asset (Tube or strip tube)
  # Stock Plates
  # Source Plates (Ie Cherrypicked)

  # Metadata
  # Read length
  # Pipeline
  # Team (Via request type)

end
