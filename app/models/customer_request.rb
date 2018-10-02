# A class for requests that have some business meaning outside of Sequencescape
class CustomerRequest < Request
  self.customer_request = true

  after_create :generate_create_request_event
  after_save :generate_request_event, if: :saved_change_to_state?
  after_save :create_billing_events, if: :can_be_billed?
  before_destroy :generate_destroy_request_event

  delegate :customer_accepts_responsibility, :customer_accepts_responsibility=, to: :request_metadata

  def update_responsibilities!
    return if qc_metrics.stock_metric.empty?
    customer_accepts_responsibility! if qc_metrics.stock_metric.all?(&:poor_quality_proceed)
  end

  def customer_accepts_responsibility!
    request_metadata.update_attributes!(customer_accepts_responsibility: true)
  end

  #
  # Generate a request event indicating the request has been created
  #
  # @return [RequestEvent] The generated request event
  #
  def generate_create_request_event
    request_events.create!(
      event_name: 'created',
      to_state: state,
      current_from: DateTime.current
    )
  end

  # Generate a request event for the state transition
  # and expires existing events
  # for existing events.
  #
  # @return [RequestEvent]  The generated request event
  #
  def generate_request_event
    time = DateTime.current
    current_request_event&.expire!(time)
    request_events.create!(
      event_name: 'state_changed',
      from_state: state_before_last_save,
      to_state: state,
      current_from: time
    )
  end

  #
  # Generate a request event indicating the request has been destroyed
  #
  # @return [RequestEvent] The generated request event
  #
  def generate_destroy_request_event
    time = DateTime.current
    current_request_event&.expire!(time)
    request_events.create!(
      event_name: 'destroyed',
      from_state: state,
      to_state: state,
      current_from: time,
      current_to: time
    )
  end

  def create_billing_events
    factory = Billing::Factory.build(self)
    factory.create! if factory.valid?
  end

  def can_be_billed?
    passed? && biffable? && billing_items.empty?
  end

  def biffable?
    billing_product.present?
  end
end
