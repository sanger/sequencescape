#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddReasonToStateChanges < ActiveRecord::Migration
  def self.up
    add_column(:state_changes, :reason, :string)
  end

  def self.down
    remove_column(:state_changes, :reason)
  end
end
