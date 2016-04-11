class AddVolumeUpdateTable < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      create_table :volume_updates do |t|
        t.integer :target_id
        t.integer :user_id
        t.float :volume_change
        t.timestamps null:false
      end
    end
  end
end
