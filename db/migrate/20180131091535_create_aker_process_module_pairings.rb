class CreateAkerProcessModulePairings < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_process_module_pairings do |t|
      t.references :from_step
      t.references :to_step
      t.references :aker_process
      t.boolean :default_path, default: false
      t.timestamps null: false
    end
  end
end
