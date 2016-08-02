#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class RemoveBatchLimitsFromPipelines < ActiveRecord::Migration
  def self.up
    Pipeline.update_all('max_size=8', 'name LIKE "%Cluster formation%"')
  end

  def self.down
    Pipeline.update_all('max_size=NULL', 'name LIKE "%Cluster formation%"')
  end
end
