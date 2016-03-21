#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class DropVisibleColumnFromSubmissionTemplates < ActiveRecord::Migration
  class SubmissionTemplate < ActiveRecord::Base
    self.table_name =('submission_templates')
    scope :should_be_hidden, -> { where('superceded_by_id != -1') }
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
