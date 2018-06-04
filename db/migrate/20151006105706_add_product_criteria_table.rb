
class AddProductCriteriaTable < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    create_table :product_criteria do |t|
      t.integer  :product_id, null: false
      t.string   :stage, null: false
      t.string   :behaviour, null: false, default: 'Basic'
      t.text     :configuration
      t.datetime :deprecated_at
      t.timestamps
    end

    add_constraint('product_criteria', 'products')
    add_constraint('qc_reports', 'product_criteria', as: 'product_criteria_id')
  end

  def self.down
    drop_constraint('product_criteria', 'products')
    drop_constraint('qc_reports', 'product_criteria')
    drop_table :product_criteria
  end
end
