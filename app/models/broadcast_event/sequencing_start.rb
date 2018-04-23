# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent::SequencingStart < BroadcastEvent
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
