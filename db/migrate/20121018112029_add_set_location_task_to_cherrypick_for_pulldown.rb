#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
