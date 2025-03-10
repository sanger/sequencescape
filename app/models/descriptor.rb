# frozen_string_literal: true
class Descriptor < ApplicationRecord
  belongs_to :task
  serialize :selection, coder: YAML

  def is_required?
    required
  end

  def matches?(search)
    search.descriptors.each { |descriptor| return true if descriptor.name == name && descriptor.value == value }
    false
  end
end
