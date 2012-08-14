class MoveSpikedInControlsToBottom < ActiveRecord::Migration
  def self.up
    Pipeline.find_by_name('HiSeq Cluster formation PE (spiked in controls)').update_attributes!(:sorter=>9)
  end

  def self.down
    Pipeline.find_by_name('HiSeq Cluster formation PE (spiked in controls)').update_attributes!(:sorter=>8)
  end
end
