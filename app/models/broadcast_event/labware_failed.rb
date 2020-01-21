# frozen_string_literal: true

# Event sent when a labware is failed
class BroadcastEvent::LabwareFailed < BroadcastEvent
  set_event_type 'labware.failed'

  seed_class Asset

  seed_subject :labware
  has_subjects(:study, :studies)
  has_subject(:labware, :labware)
  has_subjects(:sample, :contained_samples)

  has_metadata(:failure_reason) { |_asset, event| event.properties[:failure_reason] }
end
