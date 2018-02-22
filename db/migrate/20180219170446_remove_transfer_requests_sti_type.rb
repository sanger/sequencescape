# frozen_string_literal: true

# We're eliminating transfer request sub-classses, so lets nuke
# this column.
class RemoveTransferRequestsStiType < ActiveRecord::Migration[5.1]
  def change
    remove_column :transfer_requests, :sti_type, :string
  end
end
