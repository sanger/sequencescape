# frozen_string_literal: true

# @see TagGroup::AdapterType
class AddAdapterTypesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :tag_group_adapter_types do |t|
      t.string :name, unique: true
      t.timestamps
    end
  end
end
