
class AddRequestTypeIdStateIndex < ActiveRecord::Migration
  def self.up
    add_index :requests, [:request_type_id, :state], name: 'request_type_id_state_index'
  end

  def self.down
    remove_index :requests, 'request_type_id_state_index'
  end
end
