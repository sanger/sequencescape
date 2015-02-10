#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class EthicallyApprovedShouldBeNullByDefault < ActiveRecord::Migration
  def self.up
    change_column_default(:studies, :ethically_approved, nil)
  end

  def self.down
    change_column :studies, :ethically_approved, :default => false
  end
end
