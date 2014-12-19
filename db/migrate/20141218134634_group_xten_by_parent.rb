class GroupXtenByParent < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_pipeline do |pipeline|
        pipeline.update_attributes!(:group_by_parent=>true)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_pipeline do |pipeline|
        pipeline.update_attributes!(:group_by_parent=>false)
      end
    end
  end

  def self.each_pipeline
    ['HiSeq X PE (spiked in controls)','HiSeq X PE (no controls)'].each do |name|
      yield Pipeline.find_by_name!(name)
    end
  end
end
