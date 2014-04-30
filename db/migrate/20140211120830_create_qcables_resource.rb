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
