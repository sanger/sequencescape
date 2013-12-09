module Submission::Priorities

  def self.priorities
    ['None','Low','Medium','High']
  end

  def self.options
    (0...priorities.count).map do |i|
      ["#{priorities[i]} - #{i}", i]
    end
  end

  def self.included(base)
    base.class_eval do
      validates_presence_of :priority
      validates_numericality_of :priority, {:only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 3}
    end
  end


end
