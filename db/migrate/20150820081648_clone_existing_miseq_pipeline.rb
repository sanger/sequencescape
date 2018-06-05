
class CloneExistingMiseqPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      old_workflow = LabInterface::Workflow.find_by(name: 'MiSeq sequencing')
      old_workflow.deep_copy(' QC')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      LabInterface::Workflow.find_by(name: 'MiSeq sequencing QC').tap do |workflow|
        workflow.pipeline.destroy
      end.destroy
    end
  end
end
