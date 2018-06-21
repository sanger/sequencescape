
class Family < ApplicationRecord
  belongs_to :task
  belongs_to :workflow, class_name: 'Workflow', foreign_key: :pipeline_workflow_id
  has_many :assets
  has_many :descriptors, -> { order('sorter') }, dependent: :destroy
end
