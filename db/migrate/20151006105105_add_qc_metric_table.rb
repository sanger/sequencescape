
class AddQcMetricTable < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    create_table :qc_metrics do |t|
      t.integer :qc_report_id, null: false
      t.integer :asset_id, null: false
      t.text    :metrics
      t.boolean :qc_decision, null: false
      t.boolean :proceed
      t.timestamps
    end

    add_constraint('qc_metrics', 'qc_reports')
    add_constraint('qc_metrics', 'assets')
  end

  def self.down
    drop_constraint('qc_metrics', 'qc_reports')
    drop_constraint('qc_metrics', 'assets')
    drop_table :qc_metrics
  end
end
