# Rails migration
class CreateAkerContainers < ActiveRecord::Migration[4.2]
  def change
    create_table :aker_containers do |t|
      t.string :barcode
      t.string :address
      t.timestamps null: false
    end
  end
end
