class MakeUserRequestedChangesToHiseq4000 < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      Pipeline.where(name: 'HiSeq 4000 PE').first!.update_attributes!(name: 'HiSeq 4000 PE (spiked in controls)')
      Pipeline.where(name: 'HiSeq 4000 SE').first!.update_attributes!(name: 'HiSeq 4000 SE (spiked in controls)')

      both_workflows = LabInterface::Workflow.where(name: ['HiSeq 4000 PE', 'HiSeq 4000 SE'])
      pe_only = LabInterface::Workflow.where(name: 'HiSeq 4000 PE')

      Task.where(name: 'Cluster Generation', pipeline_workflow_id: both_workflows).find_each do |task|
        task.descriptors.where(kind: 'Text', sorter: 7, name: 'Pipette Carousel #').first.destroy
        task.descriptors.where(name: '-20 Temp. Read 1 Cluster Kit Lot #').first.update_attributes!(name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) Lot #')
        task.descriptors.where(name: '-20 Temp. Read 1 Cluster Kit RGT #').first.update_attributes!(name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) RGT #')
      end

      Task.where(name: 'Read 2 Lin/block/hyb/load', pipeline_workflow_id: both_workflows).find_each do |task|
        task.descriptors.where(name: '-20 Temp. Read 1 Cluster Kit Lot #').first.update_attributes!(name: '-20 Temp. Read 2 Cluster Kit (Box 2 of 2) Lot #')
        task.descriptors.where(name: '-20 Temp. Read 1 Cluster Kit RGT #').first.update_attributes!(name: '-20 Temp. Read 2 Cluster Kit (Box 2 of 2) RGT #')
      end

      Task.where(name: 'Read 2 Lin/block/hyb/load', pipeline_workflow_id: pe_only).find_each do |task|
        task.descriptors.where(name: 'AMP premix (HDR)').first.update_attributes!(name: 'AMP premix (HPM)')
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      Pipeline.where(name: 'HiSeq 4000 PE (spiked in controls)').update_attributes!(name: 'HiSeq 4000 PE')
      Pipeline.where(name: 'HiSeq 4000 SE (spiked in controls)').update_attributes!(name: 'HiSeq 4000 SE')

      both_workflows = LabInterface::Workflow.where(name: ['HiSeq 4000 PE', 'HiSeq 4000 SE'])
      pe_only = LabInterface::Workflow.where(name: 'HiSeq 4000 PE')

      Task.where(name: 'Cluster Generation', pipeline_workflow_id: both_workflows).find_each do |task|
        task.descriptors.create!(kind: 'Text', sorter: 7, name: 'Pipette Carousel #')
        task.descriptors.where(name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) Lot #').first.update_attributes!(name: '-20 Temp. Read 1 Cluster Kit Lot #')
        task.descriptors.where(name: '-20 Temp. Read 1 Cluster Kit (Box 1 of 2) RGT #').first.update_attributes!(name: '-20 Temp. Read 1 Cluster Kit RGT #')
      end

      Task.where(name: 'Read 2 Lin/block/hyb/load', pipeline_workflow_id: both_workflows).find_each do |task|
        task.descriptors.where(name: '-20 Temp. Read 2 (Box 2 of 2) Cluster Kit Lot #').first.update_attributes!(name: '-20 Temp. Read 1 Cluster Kit Lot #')
        task.descriptors.where(name: '-20 Temp. Read 2 (Box 2 of 2) Cluster Kit RGT #').first.update_attributes!(name: '-20 Temp. Read 1 Cluster Kit RGT #')
      end

      Task.where(name: 'Read 2 Lin/block/hyb/load', pipeline_workflow_id: pe_only).find_each do |task|
        task.descriptors.where(name: 'AMP premix (HPM)').first.update_attributes!(name: 'AMP premix (HDR)')
      end
    end
  end
end
