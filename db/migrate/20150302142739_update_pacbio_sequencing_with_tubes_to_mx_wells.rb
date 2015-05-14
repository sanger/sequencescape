
class UpdatePacbioSequencingWithTubesToMxWells < ActiveRecord::Migration
  class Task < ActiveRecord::Base
    set_table_name "tasks"
  end
  def self.up
    ActiveRecord::Base.transaction do
      old_task = Task.find_by_name('Layout tubes on a plate')
      pos = old_task.sorted
      Task.create!(
        :name => 'Layout tubes on a plate',
        :sti_type => 'AssignTubesToMultiplexedWellsTask',
        :sorted => pos,
        :batched => true,
        :lab_activity => true,
        :pipeline_workflow_id => LabInterface::Workflow.find_by_name('PacBio Sequencing').id
      )
      old_task.destroy
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Task.find_by_name('Layout tubes on a plate').tap do |task|
        task.sti_type='AssignTubesToWellsTask'
      end.save!
    end
  end
end
