class ChangeControlColumnDataType < ActiveRecord::Migration[5.2]

  # Change data type of control column to enum (stored as integer), from boolean
  # This is to store whether the sample is a positive or negative control, for project Heron
  # This field seemed like it hadn't been used for a while at the time of changing
  # Corresponding change in MLWH was from tinyint to string
  def up
    change_column :samples, :control, :integer
  end

  def down
    change_column :samples, :control, :boolean # rows with integer values > 1 will return true
  end
end
