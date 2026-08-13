# frozen_string_literal: true
class AddUniqueIndexToUuidsExternalId < ActiveRecord::Migration[8.0]
  def change
    remove_index :uuids, :external_id, if_exists: true
    add_index :uuids, :external_id, unique: true
  end
end
