class AddWorkCompletionTable < ActiveRecord::Migration
  def change
    create_table :work_completions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :target, null: false
      t.timestamps
    end

    add_foreign_key :work_completions, :assets, column: :target_id
  end
end
