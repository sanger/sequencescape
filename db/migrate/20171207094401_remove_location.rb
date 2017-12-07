class RemoveLocation < ActiveRecord::Migration[5.1]
  def change
    drop_table :locations
  end
end
