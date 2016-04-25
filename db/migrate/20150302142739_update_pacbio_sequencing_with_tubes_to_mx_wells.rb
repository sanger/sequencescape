#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.

class UpdatePacbioSequencingWithTubesToMxWells < ActiveRecord::Migration
  class Task < ActiveRecord::Base
    self.table_name= "tasks"
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
