class RemoveReferenceSequenceCollection < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      pacbio_wf = Pipeline.find_by_name('PacBio Sequencing').workflow
      old_task = ReferenceSequenceTask.find_by_pipeline_workflow_id(pacbio_wf.id)
      pacbio_wf.tasks.each {|task| task.update_attributes!(:sorted=>task.sorted-1) if task.sorted > old_task.sorted }
      old_task.destroy
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      pacbio_wf = Pipeline.find_by_name('PacBio Sequencing').workflow
      pacbio_wf.tasks.each {|task| task.update_attributes!(:sorted=>task.sorted+1) if task.sorted >= 2 }
      new_task = ReferenceSequenceTask.create!(
        :pipeline_workflow=> pacbio_wf,
        :sorted => 2,
        :batched => true,
        :lab_activity => true
      )
    end
  end
end
