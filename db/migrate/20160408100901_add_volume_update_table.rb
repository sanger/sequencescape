# Volume updates are performed by external applications to record transmission
# of liquid from a plate.
class AddVolumeUpdateTable < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      create_table :volume_updates do |t|
        t.integer :target_id
        t.string :created_by
        t.float :volume_change
        t.timestamps null: false
      end
    end
  end
end
