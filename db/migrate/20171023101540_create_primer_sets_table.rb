class CreatePrimerSetsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :primer_sets_tables do |t|
      t.string :name, null: false
      t.integer :snp_count, null: false
    end
  end
end
