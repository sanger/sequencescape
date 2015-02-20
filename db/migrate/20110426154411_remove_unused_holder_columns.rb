#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class RemoveUnusedHolderColumns < ActiveRecord::Migration
  def self.up
    alter_table(:assets) do 
      remove_column(:holder_type)
      remove_column(:holder_id)
    end
  end

  def self.down
    alter_table(:assets) do
      add_column(:holder_type, :string, :default => 'Location', :limit => 50)
      add_column(:holder_id, :integer)
    end
  end
end
