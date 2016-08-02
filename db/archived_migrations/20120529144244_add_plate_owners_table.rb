#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
