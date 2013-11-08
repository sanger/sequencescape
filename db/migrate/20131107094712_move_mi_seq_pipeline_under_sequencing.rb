class MoveMiSeqPipelineUnderSequencing < ActiveRecord::Migration
  def self.up
    Pipeline.find_by_name('MiSeq sequencing').update_attributes!(:group_name => 'Sequencing')
  end

  def self.down
    Pipeline.find_by_name('MiSeq sequencing').update_attributes!(:group_name => 'R&D')
  end
end
