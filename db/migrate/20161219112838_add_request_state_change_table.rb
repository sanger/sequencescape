class AddRequestStateChangeTable < ActiveRecord::Migration
  def change
    create_table :request_state_changes do |t|
      t.references :user, foreign_key: true, null: false
      t.references :target, null: false
      t.timestamps
    end

    add_foreign_key :request_state_changes, :assets, column: :target_id
  end
end
