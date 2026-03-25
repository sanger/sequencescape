# frozen_string_literal: true

# This migration adds a wafer_size column to the request_metadata table, which is used to store
# the wafer size for Ultima sequencing requests. This is stored as a string, with possible
# values of 5TB, 10TB, and 20TB at time of writing.
class AddWaferSizeToRequestMetadata < ActiveRecord::Migration[7.1]
  def change
    add_column :request_metadata, :wafer_size, :string
  end
end
