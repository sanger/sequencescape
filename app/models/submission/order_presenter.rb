# frozen_string_literal: true
class OrderPresenter # rubocop:todo Style/Documentation
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
  def id
    @target_order.id
  end

  def method_missing(method, *args, &block)
    @target_order.send(method, *args, &block)
  end
end
