# frozen_string_literal: true

# Comment arenother major source of free-text human input
class MigrateCommentsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('comments', from: 'latin1', to: 'utf8mb4')
  end
end
