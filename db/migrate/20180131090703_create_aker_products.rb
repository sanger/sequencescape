class CreateAkerProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_products do |t|
      t.string :name
      t.string :description
      t.timestamps null: false
    end
  end
end
