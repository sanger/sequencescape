class PlatePurposeRelationshipsRequestTypeIdIsNotRequired < ActiveRecord::Migration[5.1]
  def change
    change_column_null :plate_purpose_relationships, :transfer_request_type_id, true
  end
end
