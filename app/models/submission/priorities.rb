# frozen_string_literal: true
module Submission::Priorities # rubocop:todo Style/Documentation
  def self.priorities
    %w[None Low Medium High]
  end

  def self.options
    (0...priorities.count).map { |i| ["#{priorities[i]} - #{i}", i] }
  end

  def self.included(base)
    base.class_eval do
      validates :priority, presence: true
      validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
    end
  end
end
