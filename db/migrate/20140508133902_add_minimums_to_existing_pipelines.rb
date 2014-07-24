class AddMinimumsToExistingPipelines < ActiveRecord::Migration
  def self.up
    SequencingPipeline.find(:all,:conditions=>{:max_size=>8}).each do |pipeline|
      pipeline.update_attributes!(:min_size=>8)
    end
  end

  def self.down
    SequencingPipeline.find(:all,:conditions=>{:max_size=>8,:min_size=>8}).each do |pipeline|
      pipeline.update_attributes!(:min_size=>nil)
    end
  end
end
