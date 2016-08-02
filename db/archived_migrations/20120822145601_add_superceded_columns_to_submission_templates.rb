#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddSupercededColumnsToSubmissionTemplates < ActiveRecord::Migration
  def self.up
    alter_table(:submission_templates) do
      add_column(:superceded_by_id, :integer, :null => false, :default => -1)
      add_column(:superceded_at, :datetime)
    end
  end

  def self.down
    alter_table(:submission_templates) do
      remove_column(:superceded_by_id)
      remove_column(:superceded_at)
    end
  end
end
