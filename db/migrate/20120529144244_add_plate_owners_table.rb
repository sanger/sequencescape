class AddPlateOwnersTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :plate_owners do |t|
        t.integer :user_id, :null => false
        t.integer :plate_id, :null => false
        t.timestamps
      end

      connection.execute(
        'alter table plate_owners
         add constraint foreign key fk_plate_owners_to_users (user_id)
         references users (id);'
      )
      connection.execute(
         'alter table plate_owners
         add constraint foreign key fk_plate_owners_to_plates (plate_id)
         references assets (id);'
      )
    end
  end

  def self.down
    drop_table :plate_owners
  end
end
