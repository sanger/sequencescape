class XtenStripTubePipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_pipeline do |pipeline|
        pipeline.workflow.deep_copy(' Striptube').tap do |workflow|
          workflow.pipeline.request_types = [RequestType.find_by_key('hiseq_x_paired_end_sequencing')]
          workflow.pipeline.group_by_parent = true
          workflow.pipeline.save!
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_pipeline do |pipeline|
        Pipeline.find_by_name!("#{pipeline} Striptube").tap do |pl|
          pl.workflow.destroy
        end.destroy
      end
    end
  end

  def self.each_pipeline
    ['HiSeq X PE (spiked in controls)'].each do |name|
      yield Pipeline.find_by_name!(name)
    end
  end
end
