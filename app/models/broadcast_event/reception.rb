#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent::Reception < BroadcastEvent

  set_event_type 'reception'

  # Triggered whenever a plate is scanned into a new location

  # Subjects
  # Plate
  # StockPlates

  # Metadata
  # Location
end
