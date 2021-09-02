# frozen_string_literal: true

# Stamping in the 10x proces required that volume of transfer be calculated. It was persisted on transfer requests
# as part of SEQ-969
class AddVolumeToTransferRequests < ActiveRecord::Migration[5.1]
  # Adding volume to transfer_requests
  def change
    add_column :transfer_requests, :volume, :float, null: true
  end
end
