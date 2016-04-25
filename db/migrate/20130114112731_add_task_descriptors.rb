#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddTaskDescriptors < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      workflow_pairs.each do |new_workflow, old_workflow|
        new_workflow.tasks.each do |task|
          old_task = Task.find(:first, :conditions=>{:name=>task.name, :pipeline_workflow_id => old_workflow.id})
          old_task.descriptors.each do |descriptor|
            next if filtered_desriptors(task).include?(descriptor.name)
            new_descriptor = descriptor.dup
            new_descriptor.task = task
            new_descriptor.save!
          end
          new_descriptors(task).each do |desc|
            Descriptor.create!(
              :name => desc[:descriptor],
              :task => task,
              :kind => 'Text',
              :required => false,
              :sorter => desc[:order]
              )
          end
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      workflow_pairs.each do |new_workflow, old_workflow|
        new_workflow.tasks.each{|task| task.descriptors.map(&:destroy)}
      end
    end
  end

  def self.workflow_pairs
    [
      [
        Pipeline.find_by_name('HiSeq 2500 PE (spiked in controls)').workflow,
        Pipeline.find_by_name('HiSeq Cluster formation PE (spiked in controls)').workflow
      ],
      [
        Pipeline.find_by_name('HiSeq 2500 SE (spiked in controls)').workflow,
        Pipeline.find_by_name('Cluster formation SE HiSeq (spiked in controls)').workflow
      ]
    ]
  end

  def self.filtered_desriptors(task)
    case task.name
    when 'Read 1 Lin/block/hyb/load', 'Lin/block/hyb/load'
      ['Cluster Station',"Scan Mix", "Long Read FFN Mix","RDP 36",
        "Incorporation Mix", 'Incorporation Fix', "Cleavage Mix",
        "High Salt Buffer", "Incorporation Buffer","Cleavage Buffer"]
    else
      ['Cluster Station']
    end
  end

  def self.new_descriptors(task)
    case task.name
    when 'Read 1 Lin/block/hyb/load', 'Lin/block/hyb/load'
      [
        {:descriptor=>"Incorporation Mastermix", :order=> 5},
        {:descriptor=>"Universal Sequencing Buffer", :order=> 6},
        {:descriptor=>"Cleavage Reagent Master Mix", :order=> 7},
        {:descriptor=>"Scan Reagent",:order=> 8}
      ]
    else
      []
    end
  end
end
