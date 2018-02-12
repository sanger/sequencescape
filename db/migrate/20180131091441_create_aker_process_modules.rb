class CreateAkerProcessModules < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_process_modules do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
