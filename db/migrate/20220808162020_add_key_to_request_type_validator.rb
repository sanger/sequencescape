# frozen_string_literal: true

# Adds a key column to request_type_validators
class AddKeyToRequestTypeValidator < ActiveRecord::Migration[6.0]
  def change
    add_column :request_type_validators, :key, :string
    add_index :request_type_validators, :key, unique: true
  end
end
