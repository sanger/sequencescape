
class Family < ApplicationRecord
  belongs_to :task
  belongs_to :workflow, class_name: 'Workflow', foreign_key: :pipeline_workflow_id
  has_many :assets

  acts_as_descriptable :active
end
