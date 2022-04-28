# frozen_string_literal: true
class BroadcastEvent::SampleManifestCreated < BroadcastEvent
  set_event_type 'sample_manifest.created'

  seed_class SampleManifest

  has_subject(:study, :study)
  has_subjects(:labware, :labware)

  has_metadata(:labware_type, :asset_type)
  has_metadata(:supplier, :supplier_name)
end
