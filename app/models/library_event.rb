# frozen_string_literal: true
# @note This is not namespaced to assist with exposure via the API
class LibraryEvent < BroadcastEvent
  def event_type
    properties[:event_type]
  end

  def event_type=(event_type)
    self.properties ||= {}
    properties[:event_type] = event_type
  end

  # Properties takes :order_id

  seed_class Plate

  has_subjects(:study, :studies)
  has_subjects(:project, :projects)
  has_subjects(:submission, :submissions)

  has_subject(:library_source_labware, :source_plate)

  has_subjects(:stock_plate, :original_stock_plates)
  has_subjects(:order, :stock_orders)
  has_subjects(:sample, :contained_samples)

  # Not perfect, but our order type is almost always the same
  has_metadata(:order_type, :role)

  has_metadata(:team) { |plate, _e| plate.team }
end
