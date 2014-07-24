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
