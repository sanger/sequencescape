#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddFlowcellBarcodeCapture < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      pipelines.each do |name|
        SetDescriptorsTask.create!(
          :name => 'Add flowcell chip barcode',
          :pipeline_workflow_id => Pipeline.find_by_name(name).workflow.id,
          :sorted => 4,
          :batched => 1
          ).tap do |task|
            Descriptor.create!(:name=>'Chip Barcode', :sorter=>1, :task=>task, :kind=>'Text')
        end
      end
    end
  end

  def self.down
    pipelines.each do |name|
      Pipeline.find_by_name(name).workflow.tasks.each {|t| t.destroy if t.name=='Add flowcell chip barcode'}
    end
  end

  def self.pipelines
    ['HiSeq 2500 PE (spiked in controls)','HiSeq 2500 SE (spiked in controls)']
  end
end
