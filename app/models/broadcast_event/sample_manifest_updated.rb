# frozen_string_literal: true
class BroadcastEvent::SampleManifestUpdated < BroadcastEvent # rubocop:todo Style/Documentation
  set_event_type 'sample_manifest.updated'

  # Properties takes :updated_samples_ids

  seed_class SampleManifest

  has_subject(:study, :study)
  has_subjects(:labware, :labware)
  has_subjects(:sample) { |_, e| Sample.find(e.properties[:updated_samples_ids]) }

  has_metadata(:labware_type, :asset_type)
  has_metadata(:supplier, :supplier_name)
end
