# frozen_string_literal: true
class Submission::PresenterSkeleton
  class_attribute :attributes, instance_writer: false
  self.attributes = []

  delegate :not_ready_samples_names, to: :submission

  def initialize(user, submission_attributes = {})
    submission_attributes = {} if submission_attributes.blank?

    @user = user

    attributes.each { |attribute| send("#{attribute}=", submission_attributes[attribute]) }
  end

  # id accessors need to be explicitly defined...
  attr_accessor :id

  def lanes_of_sequencing
    return lanes_from_request_options if 'building pending'.include?(submission.state)

    lanes_from_request_counting
  end

  def cross_compatible?
  end

  def each_submission_warning(&)
    submission.each_submission_warning(&)
  end

  protected

  def method_missing(name, *args, &)
    name_without_assignment = name.to_s.sub(/=$/, '').to_sym
    return super unless attributes.include?(name_without_assignment)

    instance_variable_name = :"@#{name_without_assignment}"
    return instance_variable_get(instance_variable_name) if name_without_assignment == name.to_sym

    instance_variable_set(instance_variable_name, args.first)
  end

  private

  def lanes_from_request_options # rubocop:todo Metrics/AbcSize
    return order.request_options.fetch(:multiplier, {}).values.last || 1 if order.request_types[-2].nil?

    sequencing_request = RequestType.find(order.request_types.last)
    multiplier_hash = order.request_options.fetch(:multiplier, {})
    sequencing_multiplier =
      (multiplier_hash[sequencing_request.id.to_s] || multiplier_hash.fetch(sequencing_request.id, 1)).to_i

    order.multiplexed? ? sequencing_multiplier : order.assets.count * sequencing_multiplier
  end

  def lanes_from_request_counting
    submission.requests.where_is_a(SequencingRequest).count
  end
end
