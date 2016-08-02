#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSingleEnded2500Pipelines < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      cloned_pipeline = SequencingPipeline.find_by_name('Cluster formation SE HiSeq (spiked in controls)')
      cloned_pipeline.dup.tap do |pipeline|
        pipeline.name = 'HiSeq 2500 SE (spiked in controls)'
        pipeline.max_size = 2 # Can only take one tube
        pipeline.request_information_types = cloned_pipeline.request_information_types
        ['a','b','c'].each {|pl| pipeline.request_types << RequestType.find_by_key("illumina_#{pl}_hiseq_2500_single_end_sequencing") }
        pipeline.workflow = LabInterface::Workflow.create!(:name => "HiSeq 2500 SE (spiked in controls)") do |workflow|
          workflow.item_limit = 2
          workflow.locale = 'Internal'
        end.tap do |workflow|
          [
            { :class => SetDescriptorsTask,     :name => 'Specify Dilution Volume', :sorted => 1, :batched => true },
            { :class => AddSpikedInControlTask, :name => 'Add Spiked in Control',   :sorted => 2, :batched => true },
            { :class => SetDescriptorsTask,     :name => "Quality control",         :sorted => 4, :batched => true, :interactive => false, :per_item => false },
            { :class => SetDescriptorsTask,     :name => "Lin/block/hyb/load",      :sorted => 5, :batched => true, :interactive => false, :per_item => false }
          ].each do |details|
            details.delete(:class).create!(details.merge(:workflow => workflow))
          end
        end
      end.save!
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SequencingPipeline.find_by_name('HiSeq 2500 SE (spiked in controls)').destroy
      LabInterface::Workflow.find_by_name("HiSeq 2500 SE (spiked in controls)").destroy
    end
  end
end
