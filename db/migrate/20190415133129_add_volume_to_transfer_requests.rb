# frozen_string_literal: true

class AddVolumeToTransferRequests < ActiveRecord::Migration[5.1]
  # Adding volume to transfer_requests
  def change
    add_column :transfer_requests, :volume, :float, null: true
  end
end
