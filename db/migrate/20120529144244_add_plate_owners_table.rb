class AddPlateOwnersTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :plate_owners do |t|
        t.integer :user_id, :null => false
        t.integer :plate_id, :null => false
        t.timestamps
      end
#      connection.execute(%Q{
#        ALTER TABLE plate_owners
#        ADD CONSTRAINT FOREIGN KEY fk_plate_owners_to_users(user_id) REFERENCES users(id),
#        ADD CONSTRAINT FOREIGN KEY fk_plate_owners_to_plates(plate_id) REFERENCES assets(id)
#      })
    end
  end

  def self.down
    drop_table :plate_owners
  end
end
