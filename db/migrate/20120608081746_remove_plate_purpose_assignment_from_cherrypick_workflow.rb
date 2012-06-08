class RemovePlatePurposeAssignmentFromCherrypickWorkflow < ActiveRecord::Migration
  class << self
    def workflow
      Pipeline.find_by_name('Cherrypick').workflow
    end
    private :workflow

    def ensure_ordered_safely(tasks)
      tasks.each_with_index.map do |task, index|
        task.tap do
          task.sorted = index+1
          task.save(false)
        end
      end
    end
    private :ensure_ordered_safely
  end

  def self.up
    ActiveRecord::Base.transaction do
      workflow.tasks = ensure_ordered_safely(workflow.tasks.all.select { |task| !task.is_a?(AssignPlatePurposeTask) })
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      tasks = workflow.tasks.all
      tasks.insert(2, AssignPlatePurposeTask.create!(:name => 'Assign a Purpose for Output Plates'))
      workflow.tasks = ensure_ordered_safely(tasks)
    end
  end
end
