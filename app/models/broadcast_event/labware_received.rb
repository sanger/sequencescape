# frozen_string_literal: true
class BroadcastEvent::LabwareReceived < BroadcastEvent # rubocop:todo Style/Documentation
  set_event_type 'labware.received'

  seed_class Asset

  seed_subject :labware
  has_subjects(:study, :studies)
  has_subject(:labware, :labware)
  has_subjects(:sample, :contained_samples)

  has_metadata(:location_barcode) { |_asset, event| event.properties[:location_barcode] }
end
