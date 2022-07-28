# frozen_string_literal: true

# Adding reverse_read_length column to request_metadata
class AddReverseReadLengthToRequestMetadata < ActiveRecord::Migration[6.0]
  def change
    add_column :request_metadata, :reverse_read_length, :integer
  end
end
