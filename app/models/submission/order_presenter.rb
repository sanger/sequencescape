# frozen_string_literal: true
class Submission::OrderPresenter
  attr_accessor :study_id,
                :project_name,
                :plate_purpose_id,
                :sample_names_text,
                :lanes_of_sequencing_required,
                :comments

  def initialize(order)
    @target_order = order
  end

  # id needs to be defined to stop Object#id being called on the OrderPresenter
  # instance.
  delegate :id, to: :@target_order

  def method_missing(method, ...)
    @target_order.send(method, ...)
  end
end
