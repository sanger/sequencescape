class AddTablesForTagQc < ActiveRecord::Migration

  require './lib/foreign_key_constraint'

  extend ForeignKeyConstraint


  def self.up

    create_table 'lots' do |t|
      t.string     :lot_number,  :null => false
      t.references :lot_type,    :null => false
      t.references :template ,   :null => false, :polymorphic => true
      t.references :user,        :null => false
      t.date       :recieved_at, :null => false
      t.timestamps
    end
    add_index 'lots', [:lot_number,:lot_type_id], :name => 'index_lot_number_lot_type_id', :unique=>true

    create_table 'qcables' do |t|
      t.references :lot,         :null => false
      t.references :user,        :null => false
      t.references :asset,       :null => false
      t.string     :state,       :null => false
      t.timestamps
    end
    add_index 'qcables', :lot_id, :name=>'index_lot_id'
    add_index 'qcables', :asset_id, :name=>'index_asset_id'

    create_table 'stamps' do |t|
      t.references :lot,         :null => false
      t.references :user,        :null => false
      t.references :robot,       :null => false
      t.string     :tip_lot,     :null => false
      t.timestamps
    end

    create_table 'stamp_qcables' do |t|
      t.references :stamp,   :null => false
      t.references :qcable,  :null => false
      t.string     :bed,     :null => false
      t.integer    :order,   :null => false
      t.timestamps
    end

    create_table 'lot_types' do |t|
      t.string     :name,              :null => false
      t.string     :template_class,    :null => false
      t.integer    :target_purpose_id, :null => false
      t.timestamps
    end

    say "Creating foreign key constraints"

    add_constraint('lots',   'lot_types')

    add_constraint('lot_types', 'plate_purposes', :as=>'target_purpose_id')

    add_constraint('qcables','lots')
    add_constraint('qcables','users')
    add_constraint('qcables','assets')

    add_constraint('stamps','lots')
    add_constraint('stamps','users')
    add_constraint('stamps','robots')

    add_constraint('stamp_qcables','stamps')
    add_constraint('stamp_qcables','qcables')
  end

  def self.down

    drop_constraint('lots',   'lot_types')

    drop_constraint('lot_types', 'plate_purposes', :as=>'target_purpose_id')

    drop_constraint('qcables','lots')
    drop_constraint('qcables','users')
    drop_constraint('qcables','assets')

    drop_constraint('stamps','lots')
    drop_constraint('stamps','users')
    drop_constraint('stamps','robots')

    drop_constraint('stamp_qcables','stamps')
    drop_constraint('stamp_qcables','qcables')


    drop_table 'lots'
    drop_table 'qcables'
    drop_table 'stamps'
    drop_table 'stamp_qcables'
    drop_table 'lot_types'
  end
end
