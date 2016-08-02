#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class RemoveStartBatchTasks < ActiveRecord::Migration

  class StartBatchTask < Task; end;

  def self.up
    ActiveRecord::Base.transaction do
      StartBatchTask.all.each(&:destroy)
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
