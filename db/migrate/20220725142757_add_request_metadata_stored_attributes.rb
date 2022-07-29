# frozen_string_literal: true

# Adds a text field to request_metadata for storing multiple attributes
# See https://api.rubyonrails.org/classes/ActiveRecord/Store.html
class AddRequestMetadataStoredAttributes < ActiveRecord::Migration[6.0]
  def up
    add_column :request_metadata, :stored_metadata, :json
  end

  def down
    remove_column :request_metadata, :stored_metadata, :json
  end
end
