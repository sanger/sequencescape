class AddVolumeToTransferRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :transfer_requests, :volume, :float, null: true
  end
end
