class AddKeyToRequestTypeValidator < ActiveRecord::Migration[6.0]
  def change
    add_column(:request_type_validators, :key, :string, unique: true, index: true)
  end
end
