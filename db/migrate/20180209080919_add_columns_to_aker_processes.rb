class AddColumnsToAkerProcesses < ActiveRecord::Migration[5.1]
  def change
    rename_column :aker_processes, :turnaround_time, :tat
  end
end
