class ChangeControlColumnDataType < ActiveRecord::Migration[5.2]
  def up
    change_column :samples, :control, :integer
  end

  def down
    change_column :samples, :control, :boolean # rows with integer values > 1 will return true
  end
end
