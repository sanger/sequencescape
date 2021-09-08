# frozen_string_literal: true
class Descriptor < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :task
  serialize :selection

  def is_required?
    required
  end

  def matches?(search)
    search.descriptors.each { |descriptor| return true if descriptor.name == name && descriptor.value == value }
    false
  end
end
