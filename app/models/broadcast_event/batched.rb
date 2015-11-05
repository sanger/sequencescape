#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent::Batched < BroadcastEvent

  set_event_type 'batched'

  # Triggered whenever a batch is created

  # Subjects
  # Plates/Tubes as Source Labware
  # StockPlates
  # Study
  # Samples

  # Metadata
  # Request Options
  # Pipeline
end
