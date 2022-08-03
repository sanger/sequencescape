# frozen_string_literal: true

# Table flowcell_types_request_types to craete an association with request types
class CreateFlowcellTypesRequestTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :flowcell_types_request_types do |t|
      t.references :flowcell_types, null: false, foreign_key: true, type: :integer
      t.references :request_types, null: false, foreign_key: true, type: :integer
      t.integer :is_default
      t.timestamps
    end
  end
end
