class AddFileTypeToRequestMetadata < ActiveRecord::Migration
  def change
    add_column :request_metadata, :data_type, :string
  end
end
