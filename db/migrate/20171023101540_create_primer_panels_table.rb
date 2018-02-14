# frozen_string_literal: true

class CreatePrimerPanelsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :primer_panels do |t|
      t.string :name, null: false
      t.integer :snp_count, null: false
      t.timestamps null: false
    end
  end
end
