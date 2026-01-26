# frozen_string_literal: true

#
# Generated when the QC complete message comes back from NPG. Indicates that the sequencing process
# is completed, and that data should be available to the customer
#
# @author [grl]
#
class BroadcastEvent::SequencingComplete < BroadcastEvent
  set_event_type 'sequencing_complete'

  seed_class Lane
  seed_subject :lane

  # Broadcast when a sequencing request starts:
  has_subjects(:sequencing_source_labware, :source_labwares)
  has_subjects(:study, :studies)
  has_subjects(:project, :projects)
  has_subjects(:stock_plate, :original_stock_plates)
  has_subjects(:library_source_labware) { |lane, _| lane.source_labwares.map(&:library_source_plates).flatten.uniq }
  has_subjects(:sample, :samples)

  # # Metadata
  has_metadata(:read_length) { |_, e| e.lane_first_request.request_metadata.read_length }
  has_metadata(:pipeline) { |_, e| e.lane_first_request.pipeline.name }
  has_metadata(:team) { |_, e| e.lane_first_request.product_line }
  has_metadata(:result) { |_, e| e.properties[:result] }

  def lane_first_request
    Rails.logger.info("app/models/broadcast_event/sequencing_complete.rb: method - calling requests_as_target")
    seed.requests_as_target.first
  end
end
