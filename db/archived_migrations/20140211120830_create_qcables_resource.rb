#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class CreateQcablesResource < ActiveRecord::Migration
  require './lib/foreign_key_constraint'

  extend ForeignKeyConstraint


  def self.up
    create_table 'qcable_creators' do |t|
      t.references :lot,         :null => false
      t.references :user,        :null => false
      t.timestamps
    end

    add_constraint('qcable_creators','users')
  end

  def self.down
    drop_constraint('qcable_creators','users')
    drop_table 'qcable_creators'
  end
end
