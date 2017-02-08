# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class BroadcastEvent::LibraryComplete < BroadcastEvent
  set_event_type 'library_complete'

  # Properties takes :order_id

  seed_class MultiplexedLibraryTube

  has_subject(:order) { |_, e| e.order }
  has_subject(:study) { |_, e| e.order.study }
  has_subject(:project) { |_, e| e.order.project }
  has_subject(:submission) { |_, e| e.order.submission }

  has_subjects(:library_source_labware, :library_source_plates)

  has_subject(:multiplexed_library) { |tube, _e| tube }

  has_subjects(:stock_plate, :original_stock_plates)
  has_subjects(:sample) do |tube, e|
    tube.requests_as_target.for_event_notification_by_order(e.order).including_samples_from_source.map(&:samples).flatten
  end

  def order
    @order ||= Order.includes(:study, :project, :submission).find(properties[:order_id])
  end

  has_metadata(:library_type) { |_, e| e.order.request_options['library_type'] }
  has_metadata(:fragment_size_from) { |_, e| e.order.request_options['fragment_size_required_from'] }
  has_metadata(:fragment_size_to) { |_, e| e.order.request_options['fragment_size_required_to'] }
  has_metadata(:bait_library) { |_, e| e.order.request_options[:bait_library_name] }

  has_metadata(:order_type) { |_, e| e.order.order_role.try(:role) || 'UNKNOWN' }
  has_metadata(:submission_template) { |_, e| e.order.template_name }

  has_metadata(:team) { |tube, _e| tube.team || 'UNKNOWN' }
end
