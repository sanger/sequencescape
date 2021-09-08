# frozen_string_literal: true
class BroadcastEvent::SequencingStart < BroadcastEvent # rubocop:todo Style/Documentation
  set_event_type 'sequencing_start'

  seed_class Batch

  # Broadcast when a sequencing request starts:
  has_subjects(:sequencing_source_labware, :source_labware)
  has_subjects(:study, :studies)
  has_subjects(:project, :projects)
  has_subjects(:stock_plate) { |batch, _e| batch.source_labware.map(&:original_stock_plates).flatten.uniq }
  has_subjects(:library_source_labware) { |batch, _e| batch.source_labware.map(&:library_source_plates).flatten.uniq }
  has_subjects(:sample, :samples)

  # Metadata
  has_metadata(:read_length) { |batch, _e| batch.requests.first.request_metadata.read_length }
  has_metadata(:pipeline) { |batch, _e| batch.pipeline.name }
  has_metadata(:team) { |batch, _e| batch.requests.first.product_line }
end
