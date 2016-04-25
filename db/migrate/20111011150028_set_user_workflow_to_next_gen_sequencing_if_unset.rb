#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class SetUserWorkflowToNextGenSequencingIfUnset < ActiveRecord::Migration
  class Workflow < ActiveRecord::Base
    self.table_name =('submission_workflows')

    def self.default_workflow
      self.find_by_name('Next-gen sequencing') or raise StandardError, "Cannot find submission workflow 'Next-gen sequencing'"
    end
  end

  class User < ActiveRecord::Base
    self.table_name =('users')
  end

  def self.up
    User.update_all("workflow_id=#{Workflow.default_workflow.id}", 'workflow_id IS NULL')
  end

  def self.down
    # Nothing really to do here
  end
end
