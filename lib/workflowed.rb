module Workflowed
  def self.included(base)
    base.send(:belongs_to, :workflow, :class_name => "Submission::Workflow")
  end
end
