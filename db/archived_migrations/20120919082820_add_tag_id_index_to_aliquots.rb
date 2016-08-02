#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddTagIdIndexToAliquots < ActiveRecord::Migration
  def self.up
    add_index(:aliquots, :tag_id, :name => 'tag_id_idx')
  end

  def self.down
    remove_index(:aliquots, :name => 'tag_id_idx')
  end
end
