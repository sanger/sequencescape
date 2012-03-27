class AddTimestampColumnsToStudySample < ActiveRecord::Migration
  def self.up
    alter_table(:study_samples) do
      add_column(:created_at, :datetime)
      add_column(:updated_at, :datetime)
    end
  end

  def self.down
    alter_table(:study_samples) do
      remove_column(:created_at)
      remove_column(:updated_at)
    end
  end
end
