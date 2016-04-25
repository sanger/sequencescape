#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
