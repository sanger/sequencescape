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
