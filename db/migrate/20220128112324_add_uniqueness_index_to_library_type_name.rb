# frozen_string_literal: true

# Library types should be unique, otherwise things get a little confusing
class AddUniquenessIndexToLibraryTypeName < ActiveRecord::Migration[6.0]
  def change
    add_index :library_types, :name, unique: true
  end
end
