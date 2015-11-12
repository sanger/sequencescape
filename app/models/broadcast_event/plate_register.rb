#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent::PlateRegister < BroadcastEvent

  set_event_type 'plate_register'

  # Created when a plate is first registered in Sequencescape be it via plate creators,
  # plate creation or through eg cherrypicking

  seed_class PlateCreation

  # Subjects
  # Target Plate
  # Source Plates
  # Stock plates
  # origin_plate

  # Metadata
  # Plate purpose
end
