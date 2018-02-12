class CreateAkerProcesses < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_processes do |t|
      t.string :name
      t.integer :turnaround_time
      t.timestamps null: false
    end
  end
end
