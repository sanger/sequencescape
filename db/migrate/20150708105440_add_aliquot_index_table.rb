#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddAliquotIndexTable < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    create_table :aliquot_indices do |t|
      t.references :aliquot,       :null => false
      t.references :lane,          :null => false
      t.integer    :aliquot_index, :null => false
      t.timestamps
    end

    add_constraint('aliquot_indices','aliquots')
    add_constraint('aliquot_indices','assets', :as => 'lane_id')
  end

  def self.down
    drop_table :aliquot_indices
  end
end
