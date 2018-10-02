class Descriptor < ApplicationRecord
  belongs_to :task
  serialize :selection

  def is_required?
    required
  end

  def matches?(search)
    search.descriptors.each do |descriptor|
      if descriptor.name == name && descriptor.value == value
        return true
      end
    end
    false
  end
end
