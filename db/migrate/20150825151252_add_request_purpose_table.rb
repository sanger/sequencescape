
class AddRequestPurposeTable < ActiveRecord::Migration
  def self.up
    create_table :request_purposes do |t|
      t.string :key, null: false
      t.timestamps
    end
  end

  def self.down
    drop_table :request_purposes
  end
end
