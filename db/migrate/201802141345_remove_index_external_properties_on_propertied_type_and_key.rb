# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexExternalPropertiesOnPropertiedTypeAndKey < ActiveRecord::Migration[5.1]
  remove_index :external_properties, column: %w[propertied_type key]
end
