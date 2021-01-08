# frozen_string_literal: true

# Serializes lab events for the event warehouse
class BroadcastEvent::LabEvent < BroadcastEvent
  seed_class LabEvent

  def event_type
    seed.description.downcase.gsub(/[^\w]+/, '_')
  end

  def metadata
    seed.descriptor_hash
  end

  has_subject :flowcell, :flowcell
  has_subjects :sample, :samples
  has_subjects :study, :eventful_studies
  # We may not actually be a sequencing batch
  has_subjects(:sequencing_source_labware) { |seed, event| seed.eventful.sequencing? ? event.source_labware : [] }
  has_subjects(:library_source_labware) do |seed, event|
    seed.eventful.sequencing? ? event.source_labware.map(&:library_source_plates).flatten.uniq : []
  end
  has_subjects(:stock_plate) { |_seed, event| event.source_labware.map(&:original_stock_plates).flatten.uniq }

  def source_labware
    Array(seed.eventful.source_labware)
  end
end
