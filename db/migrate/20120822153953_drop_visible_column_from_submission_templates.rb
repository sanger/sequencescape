class DropVisibleColumnFromSubmissionTemplates < ActiveRecord::Migration
  class SubmissionTemplate < ActiveRecord::Base
    set_table_name('submission_templates')
    named_scope :should_be_hidden, :conditions => 'superceded_by_id != -1'
  end

  def self.up
    remove_column(:submission_templates, :visible)
  end

  def self.down
    add_column(:submission_templates, :visible, :boolean, :default => true)

    SubmissionTemplate.reset_column_information
    ActiveRecord::Base.transaction do
      SubmissionTemplate.should_be_hidden.update_all('visible=0')
    end
  end
end
