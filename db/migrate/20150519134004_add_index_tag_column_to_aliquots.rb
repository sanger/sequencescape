#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddIndexTagColumnToAliquots < ActiveRecord::Migration
  def self.up
    say "WARNING! This migration touches the aliquots table. It may take a very long time..."
    add_column :aliquots, :tag2_id, :integer, :null => false, :default=> -1
  end

  def self.down
    remove_column :aliquots, :tag2_id
  end
end
