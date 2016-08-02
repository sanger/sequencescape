#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RemoveBatchSizeRestrictionFromCherrypickForPulldown < ActiveRecord::Migration
  class Pipeline < ActiveRecord::Base
    self.table_name =('pipelines')
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
