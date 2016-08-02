#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class SetDefaultValueToLimit < ActiveRecord::Migration
  def self.up
    change_column_default :quotas, :limit, 0
  end

  def self.down
    change_column_default :quotas, :limit, nil
  end
end
