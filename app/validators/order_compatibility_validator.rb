# frozen_string_literal: true

# Orders are compatible if:
# - all of the read lengths are identical
# - all of the request types are not for mutliplexing or
# - all of the request types post the multiplexing request are the same
class OrderCompatibilityValidator < ActiveModel::Validator
  def validate(record)
    orders = record.orders
    return if orders.size < 2

    record.errors.add(:orders, 'are incompatible') unless read_lengths_identical?(orders)
    order_request_types = orders.collect { |order| OrderRequestTypes.new(order.request_types) }
    return if order_request_types.all?(&:not_for_multiplexing?)

    record.errors.add(:orders, 'are incompatible') if order_request_types.any?(&:not_for_multiplexing?)
    record.errors.add(:orders, 'are incompatible') unless order_request_types.all? do |request_types|
      request_types.post_for_multiplexing == order_request_types.first.post_for_multiplexing
    end
  end

  def read_lengths_identical?(orders)
    orders.collect { |order| order.request_options['read_length'] }.uniq.length == 1
  end

  # A nifty little class to support the validation
  class OrderRequestTypes
    attr_reader :ids, :objects

    def initialize(ids = [])
      @ids = ids
      @objects = RequestType.find(ids)
    end

    def for_multiplexing
      @for_multiplexing ||= objects.find(&:for_multiplexing?)
    end

    def for_multiplexing?
      for_multiplexing.present?
    end

    def not_for_multiplexing?
      for_multiplexing.blank?
    end

    def post_for_multiplexing
      return unless for_multiplexing?

      ids.split(for_multiplexing.id).last
    end
  end
end
