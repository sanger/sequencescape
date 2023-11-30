# frozen_string_literal: true
class BroadcastEvent::OrderMade < BroadcastEvent
  set_event_type 'order_made'

  # Properties takes :order_id

  seed_class Order

  # The seed itself can be a subject
  seed_subject :order

  # !CAUTION!
  # Be careful before changing this behaviour, as it could impact
  # on users of the events warehouse.
  # Discussion with jgrg 29/10/2020:
  # > jgrg: I guess the reason removing "event_types.key = 'order_made'" pulls in
  # > samples from other projects is that some events involve samples from
  # > multiple projects, such as when samples from multiple projects are
  # > loaded on the same flowcell. Will "order_made" always be confined to
  # > samples in our project
  #
  # This assumption is currently *true* for all order_made events, however it
  # will be potentially impacted if we change the behaviour of cross-study
  # or cross-project orders.
  #
  # A cross-study/cross-project order is currently generated if sequencing
  # is requested *directly* on multiplexed library tubes containing samples from
  # different studies/projects. This mostly occurs with re-sequencing, but
  # can also happen during GBS, custom-pooling, or situations in which the
  # sequencing request creation is deferred until after multiplexing.
  #
  # Currently these orders are not explicitly associated with *any* study/project
  # (ie. study_id and project_id on order are nil)
  # The order_made event links projects/studies as subjects only if this explicit link is present.
  # As a result, these orders have no projects/studies associated as subjects.
  #
  # If this behaviour changes in future to reference the *implicit* studies,
  # (those associated with the aliquots in the tube) then please try to generate
  # multiple Events per order. (Note you'll want to filter the samples associated
  # with the event as well)
  has_subject(:study, :study)
  has_subject(:project, :project)
  has_subject(:submission, :submission)

  has_subjects(:sample, :samples)

  has_subjects(:order_source_plate) { |_order, event| event.plates }

  has_subjects(:order_source_tubes) { |order, _event| order.assets.select { |a| a.labware.is_a?(Tube) } }

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
