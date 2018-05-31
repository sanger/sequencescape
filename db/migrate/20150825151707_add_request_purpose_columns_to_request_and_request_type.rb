
class AddRequestPurposeColumnsToRequestAndRequestType < ActiveRecord::Migration
  def self.up
    add_column :request_types, :request_purpose_id, :integer
    add_column :requests, :request_purpose_id, :integer
  end

  def self.down
    remove_column :request_types, :request_purpose_id
    remove_column :requests, :request_purpose_id
  end
end
