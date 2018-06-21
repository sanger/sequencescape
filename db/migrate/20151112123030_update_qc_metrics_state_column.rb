
class UpdateQcMetricsStateColumn < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    change_column :qc_metrics, :qc_decision, :string, null: false
  end

  def self.down
    change_column :qc_metrics, :qc_decision, :boolean, null: false
  end
end
