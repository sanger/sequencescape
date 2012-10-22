class AddTargetPurposeToRequestType < ActiveRecord::Migration
  def self.up
    add_column(:request_types, :target_purpose_id, :integer)
  end

  def self.down
    remove_column(:request_types, :target_purpose_id)
  end
end
