class AddTaskDescriptors < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      workflow_pairs.each do |new_workflow, old_workflow|
        new_workflow.tasks.each do |task|
          old_task = Task.find(:first, :conditions=>{:name=>task.name, :pipeline_workflow_id => old_workflow.id})
          old_task.descriptors.each do |descriptor|
            next if filtered_desriptors.include?(descriptor.name)
            new_descriptor = descriptor.clone
            new_descriptor.task = task
            new_descriptor.save!
          end
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      new_workflow.tasks.each{|task| task.descriptors.map(&:destroy)}
    end
  end

  def self.workflow_pairs
    [
      [Pipeline.find_by_name('HiSeq 2500 PE (spiked in controls)').workflow, Pipeline.find_by_name('HiSeq Cluster formation PE (spiked in controls)').workflow],
      [Pipeline.find_by_name('HiSeq 2500 SE (spiked in controls)').workflow, Pipeline.find_by_name('Cluster formation SE HiSeq (spiked in controls)').workflow]
    ]
  end

  def self.filtered_desriptors
    ['Cluster Station']
  end
end
