class Family < ActiveRecord::Base

  belongs_to :task
  belongs_to :workflow, :class_name => "LabInterface::Workflow", :foreign_key => :pipeline_workflow_id
  has_many :assets

  acts_as_descriptable :active

end
