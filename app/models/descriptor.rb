class Descriptor < ActiveRecord::Base
  belongs_to :task
  serialize :selection

  def is_required?
    self.required
  end

  def matches?(search)
    search.descriptors.each do |descriptor|
      if descriptor.name == self.name && descriptor.value == self.value
        return true
      end
    end
    false
  end

end
