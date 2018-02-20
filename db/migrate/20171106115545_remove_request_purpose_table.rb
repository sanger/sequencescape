class RemoveRequestPurposeTable < ActiveRecord::Migration[5.1]
  def change
    rename_column :requests, :request_purpose_id, :request_purpose
    rename_column :request_types, :request_purpose_id, :request_purpose
    drop_table :request_purposes do |t|
      t.string :key, null: false
      t.timestamps
    end
  end
end
