class AddIndexToMessengers < ActiveRecord::Migration[5.1]
  def change
    add_index :messengers, [:target_id, :target_type]
  end
end
