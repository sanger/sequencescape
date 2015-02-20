#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class UndoAssetsPreparation < ActiveRecord::Migration
  def self.up
    remove_column :assets, :has_been_visited
  end

  def self.down
    # No need to add the column as this is a unidirectional migration
  end
end
