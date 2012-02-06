class OrderPresenter
  ATTRIBUTES = [
    :study_id,
    :project_name,
    :plate_purpose_id,
    :sample_names_text,
    :lanes_of_sequencing_required,
    :comments,
  ]

  attr_accessor *ATTRIBUTES

  def initialize(order)
    @target_order = order
  end

  # id needs to be defined to stop Object#id being called on the OrderPresenter
  # instance.
  def id
    @target_order.id
  end

  def method_missing(method, *args, &block)
    @target_order.send(method, *args, &block)
  end

  # Destroys the order and if it is the last order on it's submission
  # destroy the submission too.
  def destroy
    submission = @target_order.submission

    submission.destroy unless submission.orders.size > 1
    @target_order.destroy
  end
end

