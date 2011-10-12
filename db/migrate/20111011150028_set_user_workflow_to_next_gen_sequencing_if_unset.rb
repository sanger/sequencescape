class SetUserWorkflowToNextGenSequencingIfUnset < ActiveRecord::Migration
  class Workflow < ActiveRecord::Base
    set_table_name('submission_workflows')

    def self.default_workflow
      self.find_by_name('Next-gen sequencing') or raise StandardError, "Cannot find submission workflow 'Next-gen sequencing'"
    end
  end

  class User < ActiveRecord::Base
    set_table_name('users')
  end

  def self.up
    User.update_all("workflow_id=#{Workflow.default_workflow.id}", 'workflow_id IS NULL')
  end

  def self.down
    # Nothing really to do here
  end
end
