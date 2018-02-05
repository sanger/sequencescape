# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent::SequencingComplete < BroadcastEvent
  set_event_type 'sequencing_complete'

  seed_class Lane
  seed_subject :lane

  # Broadcast when a sequencing request starts:
  has_subjects(:sequencing_source_labware) { |lane, e| e.source_labwares(lane) }
  has_subjects(:study, :studies)
  has_subjects(:project, :projects)
  has_subjects(:stock_plate) { |lane, e| e.source_labwares(lane).map(&:original_stock_plates).flatten.uniq }
  has_subjects(:library_source_labware) { |lane, e| e.source_labwares(lane).map(&:library_source_plates).flatten.uniq }
  has_subjects(:sample, :samples)

  # # Metadata
  has_metadata(:read_length) { |lane, e| e.lane_first_request(lane).request_metadata.read_length }
  has_metadata(:pipeline) { |lane, e| e.lane_first_request(lane).pipeline.name }
  has_metadata(:team) { |lane, e| e.lane_first_request(lane).product_line }


  def source_labwares(lane)
    @_source_labwares ||= {}
    @_source_labwares[lane] ||= lane.requests_as_target.map(&:asset).map(&:labware).uniq
  end

  def lane_first_request(lane)
    @_lane_first_requests ||= {}
    @_lane_first_requests[lane] ||= lane.requests_as_target.first
  end
end
