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
