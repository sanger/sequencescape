class AddTransferRequestTypeToPlatePurposeRelationships < ActiveRecord::Migration
  def self.up
    add_column(:plate_purpose_relationships, :transfer_request_type_id, :integer, :null => false)
  end

  def self.down
    remove_column(:plate_purpose_relationships, :transfer_request_type_id)
  end
end
