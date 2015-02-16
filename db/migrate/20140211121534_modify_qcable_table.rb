#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ModifyQcableTable < ActiveRecord::Migration

  require './lib/foreign_key_constraint'

  extend ForeignKeyConstraint

  class QcableCreator < ActiveRecord::Base; end

  def self.up
    drop_constraint('qcables','users')
    change_table 'qcables' do |t|
      t.references :qcable_creator, :null => false
      t.remove     :user_id
    end
  end

  def self.down
    change_table 'qcables' do |t|
      t.remove      :qcable_creator, :null => false
      t.references  :user,           :null => false
    end
    add_constraint('qcables','users')
  end
end
