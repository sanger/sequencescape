class CreateAkerProcesses < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_processes do |t|
      t.string :name
      t.integer :tat
      t.timestamps null: false
    end
  end
end
