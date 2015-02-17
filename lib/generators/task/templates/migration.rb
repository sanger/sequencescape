#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Add<%= singular_name.camelize %>Task < ActiveRecord::Migration
  def self.up
    # Fill in the workflow and the ordering of the task (sorted)
    workflow = LabInterface::Workflow.find_by_name('Fill in the workflow')
    <%= singular_name.camelize %>Task.create!( :name => '<%= singular_name.gsub(/_/,' ') %>', :sorted => 1, :batched => true, :workflow => workflow )
  end

  def self.down
  end
end
