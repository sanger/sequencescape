class AddUserToTransfer < ActiveRecord::Migration
  def change
    add_column :transfers, :user_id, :integer
  end
end
