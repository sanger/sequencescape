# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent::OrderMade < BroadcastEvent
  set_event_type 'order_made'

  # Properties takes :order_id

  seed_class Order

  # The seed itself can be a subject
  seed_subject :order
  has_subject(:study, :study)
  has_subject(:project, :project)
  has_subject(:submission, :submission)

  has_subjects(:sample, :samples)

  has_subjects(:order_source_plate) do |_order, event|
    event.plates
  end

  has_subjects(:order_source_tubes) { |order, _event| order.assets.select { |a| a.is_a?(Tube) } }

  has_subjects(:stock_plate) { |_order, event| event.plates.map(&:original_stock_plates).flatten.uniq }

  def plates
    return @plates if @plates
    wells = seed.assets.select { |a| a.is_a?(Well) }
    return [] if wells.empty?
    @plates = Plate.with_wells(wells)
  end

  has_metadata(:library_type) { |order, _e| order.request_options['library_type'] }
  has_metadata(:fragment_size_from) { |order, _e| order.request_options['fragment_size_required_from'] }
  has_metadata(:fragment_size_to) { |order, _e| order.request_options['fragment_size_required_to'] }
  has_metadata(:read_length) { |order, _e| order.request_options[:read_length] }
  has_metadata(:bait_library) { |order, _e| order.request_options[:bait_library_name] }

  has_metadata(:order_type) { |order, _e| order.order_role.try(:role) || 'UNKNOWN' }
  has_metadata(:submission_template) { |order, _e| order.template_name }
end
