#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent::SequencingStart < BroadcastEvent

  set_event_type 'sequencing_start'

  # Broadcast when a sequencing request starts:
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
