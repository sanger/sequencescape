# frozen_string_literal: true

# Event that indicates library prep is complete.
# It used to be fired (with slightly different data attached) when the multiplexed library tube was passed.
# It was moved to be fired earlier, when the 'charge and pass' button was hit in Limber, as that was felt
# to be more representative of when library prep was complete (DPL-377).
class BroadcastEvent::LibraryComplete < BroadcastEvent
  set_event_type 'library_complete'

  # Properties takes :order_id

  seed_class WorkCompletion

  has_subject(:order) { |_, e| e.order }
  has_subject(:study) { |_, e| e.order.study }
  has_subject(:project) { |_, e| e.order.project }
  has_subject(:submission) { |_, e| e.order.submission }

  has_subject(:library_source_labware) { |work_completion, _e| work_completion.target.source_plate }

  has_subjects(:stock_plate) { |work_completion, _e| work_completion.target.original_stock_plates }
  has_subjects(:sample) do |work_completion, e|
    work_completion
      .target
      Rails.logger.info("app/models/broadcast_event/library_complete.rb: method - calling requests_as_target")
      .requests_as_target
      .for_event_notification_by_order(e.order)
      .including_samples_from_source
      .map(&:samples)
      .flatten
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

  has_metadata(:team) { |_, e| RequestType.find(e.order.request_types.try(:first))&.product_line&.name || 'UNKNOWN' }
end
