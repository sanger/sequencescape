class AddMissingStepsTo2500 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      tasks.each do |details|
        details.delete(:class).create!(details.merge(:workflow => workflow))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      tasks.each do |task|
        task[:class].find(:last, :conditions => {:name => task[:name], :workflow => workflow }).destroy
      end
    end
  end

  def self.workflow
    Pipeline.find_by_name('HiSeq 2500 PE (spiked in controls)').workflow
  end

  def self.tasks
    [
      { :class => SetDescriptorsTask,     :name => 'Quality control',                   :sorted => 4, :batched => true },
      { :class => SetDescriptorsTask,     :name => 'Read 1 Lin/block/hyb/load',         :sorted => 5, :batched => true, :interactive => true, :per_item => true },
      { :class => SetDescriptorsTask,     :name => 'Read 2 Cluster/Lin/block/hyb/load', :sorted => 6, :batched => true, :interactive => true, :per_item => true }
    ]
  end
end
