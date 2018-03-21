# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexExternalPropertiesOnValue < ActiveRecord::Migration[5.1]
  remove_index :external_properties, column: ['value']
end
