# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveEpPiPt < ActiveRecord::Migration[5.1]
  remove_index :external_properties, column: %i[propertied_id propertied_type]
end
