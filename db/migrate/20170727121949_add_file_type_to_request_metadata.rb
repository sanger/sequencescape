# Rails migration
class AddFileTypeToRequestMetadata < ActiveRecord::Migration[5.1]
  def change
    add_column :request_metadata, :data_type, :string
  end
end
