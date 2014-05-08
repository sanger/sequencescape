class AddQcDecisionTables < ActiveRecord::Migration
  def self.up
    create_table 'qc_decisions' do |t|
      t.references :lot,    :null => false
      t.references :user,        :null => false
      t.timestamps
    end

    create_table 'qc_decision_qcables' do |t|
      t.references :qc_decision, :null => false
      t.references :qcable,      :null => false
      t.string     :decision,    :null => false
      t.timestamps
    end

  end

  def self.down
    drop_table 'qc_decisions'
    drop_table 'qc_decision_qcables'
  end
end
