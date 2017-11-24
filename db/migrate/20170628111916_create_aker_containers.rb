class CreateAkerContainers < ActiveRecord::Migration
  def change
    create_table :aker_containers do |t|
      t.string :barcode
      t.string :address
      t.timestamps null: false
    end
  end
end
