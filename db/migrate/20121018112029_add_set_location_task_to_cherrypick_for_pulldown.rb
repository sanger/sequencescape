class AddSetLocationTaskToCherrypickForPulldown < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      pipeline = Pipeline.find_by_name('Cherrypicking for pulldown') or raise "Cannot find pipeline"
      pipeline.workflow.tasks << SetLocationTask.create!(:name => 'Set location', :sorted => 1)
    end
  end

  def self.down
    # Ignore for the moment
  end
end
