# frozen_string_literal: true

# CreatQcResults
class CreateQcResults < ActiveRecord::Migration[5.1]
  def change
    create_table :qc_results do |t|
      t.references :asset, index: true
      t.string :key
      t.string :value
      t.string :units
      t.float :cv
      t.string :assay_type
      t.string :assay_version
      t.timestamps
    end
  end
end
