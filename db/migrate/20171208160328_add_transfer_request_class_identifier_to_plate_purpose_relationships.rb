# frozen_string_literal: true

class AddTransferRequestClassIdentifierToPlatePurposeRelationships < ActiveRecord::Migration[5.1]
  def change
    add_column :plate_purpose_relationships, :transfer_request_class_name, :integer, null: false, default: 0
  end
end
