class RemoveBatchSizeRestrictionFromCherrypickForPulldown < ActiveRecord::Migration
  class Pipeline < ActiveRecord::Base
    set_table_name('pipelines')
  end

  def self.modify(size)
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('Cherrypicking for Pulldown').update_attributes!(:max_size => size)
    end
  end

  def self.up
    modify(nil)
  end

  def self.down
    modify(96)
  end
end
