class AddFileTypeToRequestMetadata < ActiveRecord::Migration
  def change
    add_column :request_metadata, :file_type, :string
  end
end
