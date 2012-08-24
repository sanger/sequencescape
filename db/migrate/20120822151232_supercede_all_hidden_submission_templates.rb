class SupercedeAllHiddenSubmissionTemplates < ActiveRecord::Migration
  class SubmissionTemplate < ActiveRecord::Base
    set_table_name('submission_templates')
    named_scope :hidden, :conditions => { :visible => false }
  end

  def self.up
    ActiveRecord::Base.transaction do
      SubmissionTemplate.hidden.update_all('superceded_by_id=-2')
    end
  end

  def self.down
    # Nothing to do here really because we'll drop through to remove them
  end
end
