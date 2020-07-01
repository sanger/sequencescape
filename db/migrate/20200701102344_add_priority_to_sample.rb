class AddPriorityToSample < ActiveRecord::Migration[5.2]
  def change
    add_column :samples, :priority, :integer, default: 0
  end
end
