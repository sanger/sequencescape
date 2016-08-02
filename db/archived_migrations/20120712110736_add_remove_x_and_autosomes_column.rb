#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddRemoveXAndAutosomesColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :remove_x_and_autosomes, :string, :null => false, :default => 'No'
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :remove_x_and_autosomes
    end
  end
end
