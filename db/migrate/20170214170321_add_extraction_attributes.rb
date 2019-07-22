# Rails migration
class AddExtractionAttributes < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      create_table :extraction_attributes do |t|
        t.integer :target_id
        t.string :created_by
        t.text :attributes_update
        t.timestamps null: false
      end
    end
  end
end
