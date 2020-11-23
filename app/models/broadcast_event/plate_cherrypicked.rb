class BroadcastEvent::PlateCherrypicked < BroadcastEvent
  include BroadcastEvent::Helpers::ExternalSubjects

  set_event_type 'lh_beckman_cp_destination_created'

  seed_class Plate
  seed_subject :plate 

  #validate :robot_present, :source_plates_present
end